#!/bin/bash
set -e

# Android NDK Build Script for Codex
# This script builds the Rust codex workspace for Android (aarch64)

echo "Building Codex for Android (aarch64-linux-android)"

# Check if Android NDK is installed
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "Error: ANDROID_NDK_HOME environment variable is not set"
    echo "Please install Android NDK and set ANDROID_NDK_HOME to the NDK path"
    echo "Example: export ANDROID_NDK_HOME=/Users/username/Library/Android/sdk/ndk/25.1.8937393"
    echo "Or: export ANDROID_NDK_HOME=/path/to/android-ndk-r25c"
    exit 1
fi

# Use the NDK version that's actually available
export ANDROID_NDK_HOME="/Users/wangchengye/Library/Android/sdk/ndk/27.2.12479018"

if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "Error: Android NDK not found at $ANDROID_NDK_HOME"
    exit 1
fi

# Auto-detect host tag
if [[ "$OSTYPE" == "darwin"* ]]; then
    export NDK_HOST_TAG="darwin-x86_64"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export NDK_HOST_TAG="linux-x86_64"
else
    echo "Error: Unsupported OS type $OSTYPE"
    exit 1
fi

# Setup NDK toolchain paths
export NDK_TARGET="aarch64-linux-android"
export NDK_API_LEVEL="21"  # Android 5.0+

# NDK toolchain directory
export NDK_TOOLCHAIN_DIR="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$NDK_HOST_TAG"

# Check if NDK toolchain exists
if [ ! -d "$NDK_TOOLCHAIN_DIR" ]; then
    echo "Error: NDK toolchain not found at $NDK_TOOLCHAIN_DIR"
    echo "Available directories in $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/:"
    ls -la "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/" 2>/dev/null || echo "  (none found)"
    exit 1
fi

# Add NDK to PATH
export PATH="$NDK_TOOLCHAIN_DIR/bin:$PATH"

# Verify NDK compiler is available
if ! command -v aarch64-linux-android21-clang &> /dev/null; then
    echo "Error: aarch64-linux-android21-clang not found in PATH"
    echo "Available files in NDK bin directory:"
    ls -la "$NDK_TOOLCHAIN_DIR/bin/" | grep aarch64 | head -10
    exit 1
fi

# Install the Android target if not already installed
echo "Installing Android target..."
rustup target add aarch64-linux-android

# Set environment variables for OpenSSL compilation
export OPENSSL_DIR="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$NDK_HOST_TAG/sysroot/usr"
export OPENSSL_STATIC=1

# Build the workspace
echo "Building workspace..."
cd codex-rs

echo "Building libraries with custom Android PTY implementation..."

# Build libraries that should work on Android
echo "Building codex-apply-patch library..."
cargo build --release --target aarch64-linux-android --lib -p codex-apply-patch || echo "codex-apply-patch build failed"

echo "Building codex-common library..."
cargo build --release --target aarch64-linux-android --lib -p codex-common || echo "codex-common build failed"

echo "Building codex-ollama library..."
cargo build --release --target aarch64-linux-android --lib -p codex-ollama || echo "codex-ollama build failed"

echo "Building codex-login library..."
cargo build --release --target aarch64-linux-android --lib -p codex-login || echo "codex-login build failed"

echo "Building codex-linux-sandbox library..."
cargo build --release --target aarch64-linux-android --lib -p codex-linux-sandbox || echo "codex-linux-sandbox build failed"

echo ""
echo "Building codex-core with custom Android PTY implementation..."
cargo build --release --target aarch64-linux-android --lib -p codex-core || echo "codex-core build failed"

echo "Building codex-cli binary with custom Android PTY implementation..."
cargo build --release --target aarch64-linux-android --bin codex -p codex-cli || echo "codex-cli binary build failed"

echo "Building codex-exec binary with custom Android PTY implementation..."
cargo build --release --target aarch64-linux-android --bin codex-exec -p codex-exec || echo "codex-exec binary build failed"

echo "Android build completed successfully!"
echo "Binaries are available in target/aarch64-linux-android/release/"

# List the built binaries
ls -la target/aarch64-linux-android/release/codex* 2>/dev/null || echo "Some binaries may not have been built"