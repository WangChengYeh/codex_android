# Minimal Terminal using /dev/pts for Android

A minimal terminal emulator that uses `/dev/pts` pseudo-terminal functionality on Android devices.

## What it does

1. **PTY Creation**: Creates a master/slave pseudo-terminal pair using `/dev/ptmx`
2. **Shell Spawning**: Forks a child process and runs `/system/bin/sh` in the slave PTY
3. **Raw Mode**: Sets up raw terminal mode for proper character handling
4. **I/O Multiplexing**: Uses `select()` to handle bidirectional I/O between user input and shell
5. **Signal Handling**: Proper cleanup on exit with signal handlers

## Building

```bash
make
```

## Running locally (if on Linux/macOS)

```bash
make test
```

## Running on Android device

1. Build the program:
```bash
make
```

2. Push to Android device:
```bash
adb push pts_test /data/local/tmp/
adb shell chmod 755 /data/local/tmp/pts_test
```

3. Run on device:
```bash
adb shell /data/local/tmp/pts_test
```

Or use the make target:
```bash
make install
```

## Expected behavior

When working properly, you should see:
- A message showing the created PTY path (e.g., `/dev/pts/0`)
- A functional shell prompt where you can run commands
- Proper character echo and line editing
- Commands execute and display output normally
- Clean exit with Ctrl+C

## Features

- **Minimal footprint**: Statically linked, small binary
- **Raw terminal mode**: Proper character-by-character input handling  
- **Signal handling**: Clean shutdown on interruption
- **Cross-platform PTY**: Uses POSIX PTY functions for portability