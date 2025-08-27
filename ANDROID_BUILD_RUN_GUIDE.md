# Android Codex Build & Run Guide

This guide covers building, deploying, and debugging the Android Codex binary on Android devices.

## 🏗️ Prerequisites

### Development Environment
- **macOS/Linux** development machine
- **Rust 1.70+** with cross-compilation support
- **Android NDK 27.2.x** (tested) or compatible version
- **Android device** with USB debugging enabled
- **ADB** (Android Debug Bridge)
- **LLDB** for debugging (optional)
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

### Android NDK Setup
```bash
# Set NDK environment (adjust path as needed)
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.2.12479018
export PATH=$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Verify NDK installation
echo $ANDROID_NDK_HOME
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/bin/aarch64-linux-android*-clang
```

## 🔧 Environment Setup

### 1. Source Environment Variables
```bash
# Clone repository (if not already done)
git clone https://github.com/WangChengYeh/codex_android.git
cd codex_android

# Source environment variables
source sourceme
```

### 2. Set API Keys
```bash
export OPENAI_API_KEY=your_openai_api_key_here
# OR add to sourceme file (don't commit keys to git!)
```

## 🚀 Building Android Codex

### Quick Build (Recommended)
```bash
# One-command build - builds all Android components
./build-android.sh
```

**Build Output:**
- **Location**: `codex-rs/target/aarch64-linux-android/release/codex`
- **Size**: ~23MB optimized binary
- **Architecture**: ARM64 (aarch64) for modern Android devices

### Manual Build Steps
```bash
cd codex-rs

# Install Android target (if not already added)
rustup target add aarch64-linux-android

# Step-by-step build process:

# 1. Build core library
cargo build --release --target aarch64-linux-android --lib -p codex-core

# 2. Build CLI binary  
cargo build --release --target aarch64-linux-android --bin codex -p codex-cli

# 3. Build exec binary (optional)
cargo build --release --target aarch64-linux-android --bin codex-exec -p codex-exec
```

**Built binaries location:**
```
codex-rs/target/aarch64-linux-android/release/
├── codex           # Main CLI binary (~23MB)
├── codex-exec      # Exec-only binary
└── deps/           # Dependencies and intermediate files
```

### Android-Specific Build Configuration
The build uses custom configuration for Android compatibility:
- **Rustls TLS**: No OpenSSL dependency (Android compatible)
- **Custom PTY**: Android-compatible terminal handling in `core/src/android_pty.rs`
- **Modified reqwest**: Uses rustls instead of native-tls
- **Conditional portable-pty**: Excluded on Android target
- **Android home directory**: Custom detection in `config.rs`

**Key files modified for Android:**
- `codex-rs/core/Cargo.toml` - Android dependencies and rustls config
- `codex-rs/login/Cargo.toml` - rustls configuration for login module
- `codex-rs/core/src/android_pty.rs` - Android PTY implementation
- `codex-rs/core/src/config.rs` - Android-compatible home directory handling

## 🔍 Build Verification

### Check Build Success
```bash
# Verify binary was created and check size
ls -lh codex-rs/target/aarch64-linux-android/release/codex
# Should show ~23MB ARM64 binary

# Check file type (on macOS/Linux)
file codex-rs/target/aarch64-linux-android/release/codex
# Expected: ELF 64-bit LSB shared object, ARM aarch64

# Check binary size
du -h codex-rs/target/aarch64-linux-android/release/codex
```

## 🔧 Build Troubleshooting

### Common Build Issues

#### NDK Not Found Error
```bash
# Error: linker `aarch64-linux-android21-clang` not found
# Solution: Check NDK path and toolchain installation
echo $ANDROID_NDK_HOME
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/bin/aarch64-linux-android*-clang

# Fix: Update NDK path in sourceme or environment
export ANDROID_NDK_HOME=/path/to/your/ndk
```

#### OpenSSL Build Errors
```bash
# Error: failed to run custom build command for `openssl-sys`
# Solution: Project uses rustls, but some dependencies might pull OpenSSL

# Check for OpenSSL dependencies
cargo tree --target aarch64-linux-android | grep openssl

# The project is configured to avoid OpenSSL on Android
# If you see OpenSSL errors, check Cargo.toml configurations are correct
```

#### Linking Issues with NDK
```bash
# Error: unknown options: --as-needed -Bstatic
# Solution: Create proper cargo config for Android linking

mkdir -p .cargo
cat > .cargo/config.toml << EOF
[target.aarch64-linux-android]
linker = "aarch64-linux-android21-clang"
rustflags = [
    "-C", "link-arg=-fuse-ld=lld",
]
EOF
```

#### Clean Build
```bash
# Clean all build artifacts and rebuild
cargo clean

# Clean specific target
cargo clean --target aarch64-linux-android

# Rebuild from scratch
./build-android.sh
```

## 🎯 Build Variants

### Different Android Architectures
```bash
# ARM64 (recommended - modern Android devices)
cargo build --release --target aarch64-linux-android

# ARM32 (older devices)
rustup target add armv7-linux-androideabi
cargo build --release --target armv7-linux-androideabi

# x86_64 (Android emulators, x86 devices)
rustup target add x86_64-linux-android  
cargo build --release --target x86_64-linux-android

# x86 (older x86 Android devices)
rustup target add i686-linux-android
cargo build --release --target i686-linux-android
```

### Build Variants Overview
| Target | Architecture | Use Case |
|--------|--------------|----------|
| `aarch64-linux-android` | ARM64 | Modern Android devices (recommended) |
| `armv7-linux-androideabi` | ARM32 | Older Android devices |
| `x86_64-linux-android` | x86_64 | Android emulators, x86 devices |
| `i686-linux-android` | x86 | Old x86 Android devices |

## ✅ Build Success Checklist

Before proceeding to deployment, verify your build is successful:

- [ ] **Rust and Android NDK installed** - Check versions and paths
- [ ] **Android target added** - `rustup target list --installed` shows `aarch64-linux-android`
- [ ] **Environment sourced** - `source sourceme` executed successfully
- [ ] **Build completed** - `./build-android.sh` runs without errors
- [ ] **Binary created** - File exists at `codex-rs/target/aarch64-linux-android/release/codex`
- [ ] **Size verification** - Binary is approximately 23MB in size
- [ ] **File type check** - `file` command shows ARM64 ELF binary
- [ ] **No critical errors** - No unresolved linking or compilation errors

**Performance expectations:**
- **Compilation time**: 3-8 minutes (depending on hardware)
- **Binary size**: ~23MB (optimized release build)
- **Dependencies**: All bundled (static linking for portability)

## 📱 Deployment to Android Device

### 1. Connect Android Device
```bash
# Enable USB debugging on Android device
# Connect via USB
adb devices  # Verify device connection
```

### 2. Deploy Binary
```bash
# Push main binary
adb push codex-rs/target/aarch64-linux-android/release/codex /data/local/tmp/codex
adb shell chmod +x /data/local/tmp/codex

# Push exec binary (optional)
adb push codex-rs/target/aarch64-linux-android/release/codex-exec /data/local/tmp/codex-exec
adb shell chmod +x /data/local/tmp/codex-exec
```

### 3. Test Deployment
```bash
adb shell "/data/local/tmp/codex --version"
# Expected output: codex-cli 0.0.0
```

## 🎯 Running Android Codex

### Basic Usage
```bash
# Start ADB shell
adb shell

# Navigate to binary location
cd /data/local/tmp

# Set API key (required for OpenAI API access)
export OPENAI_API_KEY=your_key_here

# CRITICAL: Set HOME to writable directory (fixes rollout recorder error)
export HOME=/data/local/tmp

# Run basic commands
./codex --help
./codex --version

# Execute with prompt
./codex exec --skip-git-repo-check "Your prompt here"
```

### Example Commands
```bash
# Always set these first (in every session):
export OPENAI_API_KEY=your_key_here
export HOME=/data/local/tmp

# System analysis
./codex exec --skip-git-repo-check "Analyze this Android system and show hardware info"

# Code generation
./codex exec --skip-git-repo-check "Create a shell script to monitor system resources"

# File operations
./codex exec --skip-git-repo-check "List all files in current directory and explain their purposes"

# With different sandbox modes (HOME workaround enables file writing)
./codex exec --skip-git-repo-check --sandbox workspace-write "Create a test file"
```

### Working Examples from Testing
1. **System Analysis**: Complete Android 14 environment inspection
2. **Code Generation**: Created functional system monitoring scripts
3. **File Operations**: Directory listing, file reading, permissions checking  
4. **Process Monitoring**: CPU, memory, storage analysis

## 🐛 Debugging

### Using MCP Pexpect (Automated)
```bash
# Run comprehensive debugging session
python3 android_lldb_debug.py

# Simple deployment test  
python3 android_deploy_simple.py

# Full deployment with debugging
python3 android_deploy_debug.py
```

### Manual LLDB Debugging
```bash
# On Android device (requires root or lldb-server)
adb shell "/data/local/tmp/lldb-server platform --listen '*:5039' --server"

# On host machine
adb forward tcp:5039 tcp:5039
lldb
(lldb) platform select remote-android
(lldb) platform connect connect://localhost:5039
(lldb) attach -p <PID>
```

### Process Monitoring
```bash
# Find running Codex processes
adb shell "ps | grep codex"

# Monitor system resources
adb shell "cat /proc/meminfo | head -10"
adb shell "cat /proc/cpuinfo | head -10"

# Check storage
adb shell "df -h /data/local/tmp"
```

## 📊 Performance Characteristics

- **Binary Size**: ~23MB (optimized release build)
- **Memory Usage**: ~50-100MB runtime
- **Response Time**: 15-45 seconds for complex queries
- **Model**: GPT-5 with reasoning effort: medium
- **Token Usage**: ~8K-11K tokens per complex request

## ⚠️ Known Limitations

### Sandbox Restrictions
- **Read-only** sandbox by default (prevents file writing)
- Some commands blocked by allowlist
- Rollout recorder fails (read-only filesystem error)

### Android Shell Limitations
- `bash` not available (uses `sh`)
- Some standard Linux commands unavailable
- Android-specific command set

### Solutions
```bash
# CRITICAL: Always set HOME to fix rollout recorder error
export HOME=/data/local/tmp

# Use workspace-write for file operations
./codex exec --skip-git-repo-check --sandbox workspace-write "command"

# Skip git repo check for non-git directories
./codex exec --skip-git-repo-check "command"
```

## 🔧 Troubleshooting

### Build Issues
```bash
# Clean build
cargo clean
./build-android.sh

# Check NDK path
echo $ANDROID_NDK_HOME
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/
```

### Runtime Issues
```bash
# Check device connection
adb devices

# Verify binary permissions
adb shell "ls -la /data/local/tmp/codex"

# Test basic execution
adb shell "cd /data/local/tmp && ./codex --version"
```

### Authentication Issues
```bash
# Verify API key is set
adb shell "echo \$OPENAI_API_KEY"

# Test with explicit key
adb shell "export OPENAI_API_KEY='your_key' && /data/local/tmp/codex --version"
```

## 📁 File Structure

```
codex_android/
├── build-android.sh              # Main build script
├── android_codex_binary          # Compiled Android binary (23MB)
├── android_deploy_debug.py       # MCP pexpect debugging script  
├── android_deploy_simple.py      # Simple deployment test
├── android_lldb_debug.py         # Comprehensive LLDB debugging
├── test_android_minimal/         # Minimal test project
├── sourceme                      # Environment setup
└── codex-rs/                     # Rust source code
    ├── core/src/android_pty.rs   # Android PTY implementation
    ├── core/src/exec_command/     # Android session management
    └── target/aarch64-linux-android/release/
        ├── codex                  # Main CLI binary
        └── codex-exec             # Exec-only binary
```

## ✅ Verification

To verify your Android Codex setup works correctly:

```bash
# 1. Build verification
./build-android.sh && echo "✅ Build successful"

# 2. Deployment verification  
adb push android_codex_binary /data/local/tmp/codex
adb shell chmod +x /data/local/tmp/codex
adb shell "/data/local/tmp/codex --version" && echo "✅ Deployment successful"

# 3. Authentication verification
source sourceme
adb shell "export OPENAI_API_KEY='$OPENAI_API_KEY' && cd /data/local/tmp && ./codex exec --skip-git-repo-check 'echo Hello Android Codex'" && echo "✅ Authentication successful"

# 4. Full functionality verification
python3 android_lldb_debug.py && echo "✅ Full debugging stack operational"
```

## 🚀 Ready for Production

Your Android Codex is ready when you see:
- ✅ Binary builds without errors (23MB release build)
- ✅ Device deployment successful 
- ✅ Version command returns `codex-cli 0.0.0`
- ✅ Authenticated commands execute with API responses
- ✅ System analysis and code generation working
- ✅ MCP pexpect automation scripts operational

**The Android Codex is now fully functional and ready for advanced AI-assisted development on Android devices!** 🎉