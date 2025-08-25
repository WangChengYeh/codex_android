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

# Build specific binaries for Android
echo "Building codex CLI binary..."
cargo build --release --target aarch64-linux-android --bin codex

echo "Building codex-exec binary..."
cargo build --release --target aarch64-linux-android --bin codex-exec

echo "Building codex-linux-sandbox binary..."
cargo build --release --target aarch64-linux-android --bin codex-linux-sandbox

echo "Android build completed successfully!"
echo "Binaries are available in target/aarch64-linux-android/release/"

# List the built binaries
ls -la target/aarch64-linux-android/release/codex* 2>/dev/null || echo "Some binaries may not have been built"