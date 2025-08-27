# Android Codex Build & Run Guide

This guide covers building, deploying, and debugging the Android Codex binary on Android devices.

## 🏗️ Prerequisites

### Development Environment
- **macOS/Linux** development machine
- **Android NDK 27.2.x** or compatible
- **Rust toolchain** with Android target support
- **Android device** with USB debugging enabled
- **ADB** (Android Debug Bridge)
- **LLDB** for debugging (optional)

### Required Tools
```bash
# Install Rust and Android target
rustup target add aarch64-linux-android

# Android SDK/NDK setup
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.2.12479018
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

## 🔧 Environment Setup

### 1. Source Environment Variables
```bash
source sourceme
```

### 2. Set API Keys
```bash
export OPENAI_API_KEY=your_openai_api_key_here
# OR add to sourceme file (don't commit keys to git!)
```

## 🚀 Building Android Codex

### Quick Build
```bash
# Build all Android components
./build-android.sh
```

### Manual Build Steps
```bash
cd codex-rs

# Install Android target
rustup target add aarch64-linux-android

# Build individual components
cargo build --release --target aarch64-linux-android --lib -p codex-core
cargo build --release --target aarch64-linux-android --bin codex -p codex-cli
cargo build --release --target aarch64-linux-android --bin codex-exec -p codex-exec

# Built binaries location:
# target/aarch64-linux-android/release/codex
# target/aarch64-linux-android/release/codex-exec
```

### Build Configuration
The build uses custom configuration for Android:
- **Rustls TLS** instead of OpenSSL (Android compatibility)
- **Custom PTY implementation** for Android terminals
- **Android-specific home directory** detection
- **Landlock sandboxing** for Linux/Android security

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

# Run basic commands
./codex --help
./codex --version

# Execute with prompt
./codex exec --skip-git-repo-check "Your prompt here"
```

### Example Commands
```bash
# System analysis
./codex exec --skip-git-repo-check "Analyze this Android system and show hardware info"

# Code generation
./codex exec --skip-git-repo-check "Create a shell script to monitor system resources"

# File operations
./codex exec --skip-git-repo-check "List all files in current directory and explain their purposes"

# With different sandbox modes
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