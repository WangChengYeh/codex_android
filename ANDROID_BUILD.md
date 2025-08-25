# Building Codex for Android

This document explains how to build the Codex Rust workspace for Android targets.

## Prerequisites

### 1. Android NDK
- Download and install Android NDK from [developer.android.com](https://developer.android.com/ndk/downloads)
- Set the `ANDROID_NDK_HOME` environment variable to point to your NDK installation
- Recommended NDK version: r25c or later

Example:
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk-r25c
```

### 2. Rust Android Target
The build script will automatically install the Android target, but you can also install it manually:
```bash
rustup target add aarch64-linux-android
```

### 3. NDK Host Tag
The build script assumes macOS (`darwin-x86_64`). If building on Linux, edit `build-android.sh` and change:
```bash
export NDK_HOST_TAG="linux-x86_64"
```

## Building

### Quick Build
Run the provided build script:
```bash
./build-android.sh
```

### Manual Build
If you prefer to build manually:

1. Set up environment variables:
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk
export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"
```

2. Install the Android target:
```bash
rustup target add aarch64-linux-android
```

3. Build the workspace:
```bash
cd codex-rs
cargo build --release --target aarch64-linux-android
```

## Build Status

### ✅ Successfully Built Libraries

The following libraries build successfully for Android (`aarch64-linux-android`):

- `libcodex_apply_patch.rlib` - Code patch application functionality
- `libcodex_common.rlib` - Common utilities and shared code
- `libcodex_linux_sandbox.rlib` - Sandbox functionality (works on Android) 
- `libcodex_ollama.rlib` - Ollama integration

### ❌ Known Limitations

**Libraries that fail to build:**
- `codex-login` - Fails due to OpenSSL header detection issues
- `codex-core` - Contains portable-pty dependency using `openpty()` not available on Android
- `codex-cli` - Depends on core library and TUI functionality
- `codex-exec` - Depends on core library for process execution

**Root Cause:**
The `portable-pty` crate uses `openpty()` system call which is not available on Android. Android uses different TTY/PTY management compared to desktop Linux, and full TUI functionality requires Android-specific terminal handling.

## Android-Specific Changes

The following modifications were made to support Android:

1. **Workspace Configuration**: Added Android target configuration in root `Cargo.toml`
2. **OpenSSL**: Configured to build from source for Android target
3. **Linux Sandbox**: Extended to support Android (uses Linux kernel APIs)
4. **Conditional Compilation**: Updated platform checks to include Android alongside Linux
5. **NDK Integration**: Added cargo config for Android NDK toolchain

## Troubleshooting

### NDK Not Found
```
Error: ANDROID_NDK_HOME environment variable is not set
```
Solution: Install Android NDK and set the environment variable.

### Target Not Found
```
error: couldn't find the Android target
```
Solution: Install the Android target with `rustup target add aarch64-linux-android`

### Linker Errors
If you encounter linker errors, ensure:
1. NDK toolchain is in your PATH
2. The correct NDK host tag is set in the build script
3. API level is appropriate (21+ recommended)

### OpenSSL Build Issues
The build uses vendored OpenSSL. If you encounter issues:
1. Ensure `openssl-sys` has the `vendored` feature enabled
2. Check that NDK provides the necessary build tools

## Notes

- Only aarch64 Android target is currently configured
- Minimum Android API level is 21 (Android 5.0)
- The sandbox functionality uses Linux kernel APIs available on Android
- Built binaries can be used in Android environments that support native executables