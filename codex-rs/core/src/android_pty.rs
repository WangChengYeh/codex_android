use std::fs::OpenOptions;
use std::io::{self, Read, Write};
use std::os::unix::io::{FromRawFd, IntoRawFd, RawFd};
use std::os::unix::process::CommandExt;
use std::process::{Child, Command, Stdio};

/// Android-compatible PTY implementation that directly uses /dev/pts
pub struct AndroidPty {
    pub master_fd: RawFd,
    pub slave_path: String,
}

pub struct AndroidPtyMaster {
    fd: RawFd,
}

pub struct AndroidPtySlave {
    fd: RawFd,
    path: String,
}

impl AndroidPty {
    /// Create a new PTY pair using Android's /dev/pts system
    pub fn new() -> io::Result<(AndroidPtyMaster, AndroidPtySlave)> {
        unsafe {
            // Open /dev/ptmx to create a new PTY
            let ptmx = OpenOptions::new()
                .read(true)
                .write(true)
                .open("/dev/ptmx")?;
            
            let master_fd = ptmx.into_raw_fd();
            
            // Grant access to the slave PTY
            if libc::grantpt(master_fd) != 0 {
                libc::close(master_fd);
                return Err(io::Error::last_os_error());
            }
            
            // Unlock the slave PTY
            if libc::unlockpt(master_fd) != 0 {
                libc::close(master_fd);
                return Err(io::Error::last_os_error());
            }
            
            // Get the path to the slave PTY
            let slave_name_ptr = libc::ptsname(master_fd);
            if slave_name_ptr.is_null() {
                libc::close(master_fd);
                return Err(io::Error::last_os_error());
            }
            
            let slave_path = std::ffi::CStr::from_ptr(slave_name_ptr)
                .to_string_lossy()
                .into_owned();
            
            // Open the slave PTY
            let slave = OpenOptions::new()
                .read(true)
                .write(true)
                .open(&slave_path)?;
            
            let slave_fd = slave.into_raw_fd();
            
            Ok((
                AndroidPtyMaster { fd: master_fd },
                AndroidPtySlave { fd: slave_fd, path: slave_path }
            ))
        }
    }
}

impl AndroidPtyMaster {
    pub fn try_clone_reader(&self) -> io::Result<AndroidPtyReader> {
        unsafe {
            let new_fd = libc::dup(self.fd);
            if new_fd == -1 {
                return Err(io::Error::last_os_error());
            }
            Ok(AndroidPtyReader { fd: new_fd })
        }
    }
    
    pub fn take_writer(self) -> io::Result<AndroidPtyWriter> {
        Ok(AndroidPtyWriter { fd: self.fd })
    }
}

impl AndroidPtySlave {
    pub fn spawn_command(&self, mut cmd: Command) -> io::Result<Child> {
        // Configure the command to use the PTY as stdin/stdout/stderr
        unsafe {
            let slave_file = std::fs::File::from_raw_fd(libc::dup(self.fd));
            let stdio = Stdio::from(slave_file);
            
            cmd.stdin(stdio);
            // Clone for stdout and stderr
            let stdout_file = std::fs::File::from_raw_fd(libc::dup(self.fd));
            let stderr_file = std::fs::File::from_raw_fd(libc::dup(self.fd));
            cmd.stdout(Stdio::from(stdout_file));
            cmd.stderr(Stdio::from(stderr_file));
            
            // Set up session and process group
            cmd.pre_exec(|| {
                // Create a new session
                if libc::setsid() == -1 {
                    return Err(io::Error::last_os_error());
                }
                
                // Make this the controlling terminal
                if libc::ioctl(0, libc::TIOCSCTTY, 0) == -1 {
                    // This might fail on Android, but continue anyway
                }
                
                Ok(())
            });
        }
        
        cmd.spawn()
    }
}

pub struct AndroidPtyReader {
    fd: RawFd,
}

impl Read for AndroidPtyReader {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        unsafe {
            let result = libc::read(self.fd, buf.as_mut_ptr() as *mut libc::c_void, buf.len());
            if result == -1 {
                Err(io::Error::last_os_error())
            } else {
                Ok(result as usize)
            }
        }
    }
}

impl Drop for AndroidPtyReader {
    fn drop(&mut self) {
        unsafe {
            libc::close(self.fd);
        }
    }
}

pub struct AndroidPtyWriter {
    fd: RawFd,
}

impl Write for AndroidPtyWriter {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        unsafe {
            let result = libc::write(self.fd, buf.as_ptr() as *const libc::c_void, buf.len());
            if result == -1 {
                Err(io::Error::last_os_error())
            } else {
                Ok(result as usize)
            }
        }
    }
    
    fn flush(&mut self) -> io::Result<()> {
        unsafe {
            if libc::fsync(self.fd) == -1 {
                Err(io::Error::last_os_error())
            } else {
                Ok(())
            }
        }
    }
}

impl Drop for AndroidPtyWriter {
    fn drop(&mut self) {
        unsafe {
            libc::close(self.fd);
        }
    }
}

impl Drop for AndroidPtyMaster {
    fn drop(&mut self) {
        unsafe {
            libc::close(self.fd);
        }
    }
}

impl Drop for AndroidPtySlave {
    fn drop(&mut self) {
        unsafe {
            libc::close(self.fd);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::process::Command;
    
    #[test]
    fn test_android_pty_creation() {
        let result = AndroidPty::new();
        assert!(result.is_ok(), "Failed to create Android PTY: {:?}", result.err());
        
        let (_master, slave) = result.unwrap();
        assert!(slave.path.starts_with("/dev/pts/"));
    }
    
    #[test]
    fn test_android_pty_echo() {
        let (master, slave) = AndroidPty::new().expect("Failed to create PTY");
        
        let mut reader = master.try_clone_reader().expect("Failed to clone reader");
        let mut writer = master.take_writer().expect("Failed to take writer");
        
        // Spawn echo command
        let mut cmd = Command::new("echo");
        cmd.arg("hello world");
        let _child = slave.spawn_command(cmd).expect("Failed to spawn command");
        
        // Read output
        let mut buf = [0u8; 1024];
        std::thread::sleep(std::time::Duration::from_millis(100));
        let n = reader.read(&mut buf).expect("Failed to read from PTY");
        let output = String::from_utf8_lossy(&buf[..n]);
        
        assert!(output.contains("hello world"));
    }
}