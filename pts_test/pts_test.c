#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <signal.h>
#include <sys/select.h>

static int master_fd = -1;
static pid_t shell_pid = -1;
static struct termios orig_termios;
static int stdin_is_tty = 0;

void cleanup() {
    if (stdin_is_tty) {
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
    }
    if (master_fd != -1) {
        close(master_fd);
    }
    if (shell_pid > 0) {
        kill(shell_pid, SIGTERM);
        waitpid(shell_pid, NULL, 0);
    }
}

void signal_handler(int sig) {
    (void)sig;
    cleanup();
    exit(0);
}

int setup_raw_mode() {
    if (!isatty(STDIN_FILENO)) {
        return 0;
    }
    
    stdin_is_tty = 1;
    if (tcgetattr(STDIN_FILENO, &orig_termios) < 0) {
        perror("tcgetattr");
        return -1;
    }
    
    struct termios raw = orig_termios;
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag &= ~(OPOST);
    raw.c_cflag |= (CS8);
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_cc[VMIN] = 1;
    raw.c_cc[VTIME] = 0;
    
    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) < 0) {
        perror("tcsetattr");
        return -1;
    }
    
    return 0;
}

int create_pty() {
    char slave_name[256];
    
    master_fd = posix_openpt(O_RDWR | O_NOCTTY);
    if (master_fd < 0) {
        perror("posix_openpt");
        return -1;
    }
    
    if (grantpt(master_fd) < 0) {
        perror("grantpt");
        close(master_fd);
        return -1;
    }
    
    if (unlockpt(master_fd) < 0) {
        perror("unlockpt");
        close(master_fd);
        return -1;
    }
    
    if (ptsname_r(master_fd, slave_name, sizeof(slave_name)) < 0) {
        perror("ptsname_r");
        close(master_fd);
        return -1;
    }
    
    printf("Created pty: %s\n", slave_name);
    return 0;
}

int spawn_shell() {
    shell_pid = fork();
    if (shell_pid < 0) {
        perror("fork");
        return -1;
    }
    
    if (shell_pid == 0) {
        setsid();
        
        char slave_name[256];
        if (ptsname_r(master_fd, slave_name, sizeof(slave_name)) < 0) {
            perror("ptsname_r in child");
            exit(1);
        }
        
        int slave_fd = open(slave_name, O_RDWR);
        if (slave_fd < 0) {
            perror("open slave");
            exit(1);
        }
        
        if (ioctl(slave_fd, TIOCSCTTY, 0) < 0) {
            perror("ioctl TIOCSCTTY");
            exit(1);
        }
        
        dup2(slave_fd, STDIN_FILENO);
        dup2(slave_fd, STDOUT_FILENO);
        dup2(slave_fd, STDERR_FILENO);
        
        if (slave_fd > 2) {
            close(slave_fd);
        }
        close(master_fd);
        
        struct winsize ws = {24, 80, 0, 0};
        ioctl(STDIN_FILENO, TIOCSWINSZ, &ws);
        
        char *shell = getenv("SHELL");
        if (!shell) {
            shell = "/system/bin/sh";
        }
        
        execl(shell, shell, NULL);
        perror("execl");
        exit(1);
    }
    
    return 0;
}

void terminal_loop() {
    fd_set readfds;
    char buffer[4096];
    ssize_t n;
    
    printf("Minimal terminal started. Press Ctrl+C to exit.\n");
    
    while (1) {
        FD_ZERO(&readfds);
        FD_SET(STDIN_FILENO, &readfds);
        FD_SET(master_fd, &readfds);
        
        int max_fd = (master_fd > STDIN_FILENO) ? master_fd : STDIN_FILENO;
        
        if (select(max_fd + 1, &readfds, NULL, NULL, NULL) < 0) {
            if (errno == EINTR) continue;
            perror("select");
            break;
        }
        
        if (FD_ISSET(STDIN_FILENO, &readfds)) {
            n = read(STDIN_FILENO, buffer, sizeof(buffer));
            if (n <= 0) break;
            
            if (write(master_fd, buffer, n) < 0) {
                perror("write to master");
                break;
            }
        }
        
        if (FD_ISSET(master_fd, &readfds)) {
            n = read(master_fd, buffer, sizeof(buffer));
            if (n <= 0) break;
            
            if (write(STDOUT_FILENO, buffer, n) < 0) {
                perror("write to stdout");
                break;
            }
        }
        
        int status;
        if (waitpid(shell_pid, &status, WNOHANG) > 0) {
            printf("\nShell exited.\n");
            break;
        }
    }
}

int main() {
    printf("Minimal Terminal using /dev/pts\n");
    printf("===============================\n");
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    atexit(cleanup);
    
    if (create_pty() < 0) {
        fprintf(stderr, "Failed to create pty\n");
        return 1;
    }
    
    if (setup_raw_mode() < 0) {
        fprintf(stderr, "Failed to setup raw mode\n");
        return 1;
    }
    
    if (spawn_shell() < 0) {
        fprintf(stderr, "Failed to spawn shell\n");
        return 1;
    }
    
    terminal_loop();
    
    return 0;
}