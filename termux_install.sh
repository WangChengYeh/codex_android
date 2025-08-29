#!/data/data/com.termux/files/usr/bin/bash
# Termux Installation Script for Android Codex

set -e

echo "=== Installing Android Codex in Termux ==="
echo

# Check if package exists
if [ ! -f "/sdcard/android-codex-cli-0.25.0-aarch64.deb" ]; then
    echo "❌ Package not found at /sdcard/android-codex-cli-0.25.0-aarch64.deb"
    echo "Please ensure the package was pushed to the device first"
    exit 1
fi

# Copy to Termux directory
echo "📋 Copying package to Termux directory..."
cp /sdcard/android-codex-cli-0.25.0-aarch64.deb ~/

# Install the package
echo "📦 Installing Android Codex package..."
pkg install ~/android-codex-cli-0.25.0-aarch64.deb

# Run setup
echo "🔧 Running initial setup..."
codex-setup

echo "✅ Installation complete!"
echo "Usage: codex exec 'Your prompt here'"
