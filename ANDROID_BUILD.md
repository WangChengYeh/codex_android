# Android Build Guide for Codex

Complete guide for building Codex for Android devices from source code.

## 🏗️ Build Prerequisites

### System Requirements
- **macOS/Linux** development machine
- **Rust 1.70+** with cross-compilation support  
- **Android NDK 27.2.x** (tested) or compatible version
- **Git** for cloning repository

### Install Dependencies
```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Add Android target
rustup target add aarch64-linux-android

# Install Android SDK/NDK (via Android Studio or standalone)
# Or using Homebrew on macOS:
brew install --cask android-studio
```

## 🚀 Quick Build

### One-Command Build
```bash
# Clone and build in one go
git clone https://github.com/WangChengYeh/codex_android.git
cd codex_android
source sourceme
./build-android.sh
```

### Build Output
- **Location**: `codex-rs/target/aarch64-linux-android/release/codex`
- **Size**: ~23MB optimized binary
- **Architecture**: ARM64 (aarch64) for modern Android devices

## 🔧 Manual Build Process

### Environment Setup
```bash
# Set NDK environment (adjust path as needed)
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.2.12479018
export PATH=$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin

# Verify NDK
echo $ANDROID_NDK_HOME
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/bin/aarch64-linux-android*-clang
```

### Step-by-Step Build
```bash
cd codex-rs

# 1. Build core library
cargo build --release --target aarch64-linux-android --lib -p codex-core

# 2. Build CLI binary  
cargo build --release --target aarch64-linux-android --bin codex -p codex-cli

# 3. Build exec binary (optional)
cargo build --release --target aarch64-linux-android --bin codex-exec -p codex-exec
```

## 🔍 Build Troubleshooting

### Common Issues & Solutions

#### NDK Not Found
```bash
# Error: linker `aarch64-linux-android21-clang` not found
# Solution: Install and configure NDK properly
export ANDROID_NDK_HOME=/path/to/your/ndk
```

#### OpenSSL Linking Issues
```bash
# Error: OpenSSL build failed
# Solution: Project uses rustls, check Cargo.toml is properly configured
# The project automatically handles this with Android-specific deps
```

#### Clean Build
```bash
cargo clean
./build-android.sh  # Rebuild from scratch
```

## 📋 Build Verification

### Check Build Success
```bash
# Verify binary exists and size
ls -lh codex-rs/target/aarch64-linux-android/release/codex
# Should show ~23MB ARM64 binary

# Check file type
file codex-rs/target/aarch64-linux-android/release/codex
# Should show: ELF 64-bit LSB shared object, ARM aarch64
```

### Test on Device
```bash
# Deploy to Android device
./android_setup.sh

# Or manually:
adb push codex-rs/target/aarch64-linux-android/release/codex /data/local/tmp/codex
adb shell chmod +x /data/local/tmp/codex
adb shell "/data/local/tmp/codex --version"
```

## ⚙️ Build Configuration

### Android-Specific Features
- **Rustls TLS**: No OpenSSL dependency (Android compatible)
- **Custom PTY**: Android-compatible terminal handling
- **Modified reqwest**: Uses rustls instead of native-tls
- **Conditional portable-pty**: Excluded on Android target

### Key Files Modified for Android
- `codex-rs/core/Cargo.toml` - Android dependencies
- `codex-rs/login/Cargo.toml` - rustls configuration  
- `codex-rs/core/src/android_pty.rs` - Android PTY implementation
- `codex-rs/core/src/config.rs` - Android home directory handling

## 🎯 Build Variants

### Different Targets
```bash
# ARM64 (recommended - modern devices)
cargo build --release --target aarch64-linux-android

# ARM32 (older devices)
rustup target add armv7-linux-androideabi
cargo build --release --target armv7-linux-androideabi

# x86_64 (emulators)
rustup target add x86_64-linux-android  
cargo build --release --target x86_64-linux-android
```

## ✅ Build Success Checklist

- [ ] Rust and Android NDK installed
- [ ] Android target added: `rustup target add aarch64-linux-android`
- [ ] Environment sourced: `source sourceme`
- [ ] Build script runs without errors: `./build-android.sh`
- [ ] Binary created: `ls codex-rs/target/aarch64-linux-android/release/codex`
- [ ] Size check: ~23MB optimized binary
- [ ] Device deployment successful
- [ ] Version command works: `codex --version` returns `codex-cli 0.0.0`

## 🚀 Next Steps

After successful build:
1. **Deploy**: Use `./android_setup.sh` for easy deployment
2. **Configure**: Set `export HOME=/data/local/tmp` on Android (critical!)
3. **Test**: Run `./codex exec --skip-git-repo-check "Hello Android"`
4. **Develop**: Ready for AI-assisted Android development!

**Build complete - ready for Android! 🎉**