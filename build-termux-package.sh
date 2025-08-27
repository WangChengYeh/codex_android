#!/bin/bash
# Build Android Codex Termux Package

set -e

PACKAGE_NAME="codex-android"
VERSION="0.0.1"
ARCH="aarch64"
BUILD_DIR="termux-package-build"

echo "=== Building Termux Package for Android Codex ==="
echo "Package: $PACKAGE_NAME"
echo "Version: $VERSION" 
echo "Architecture: $ARCH"
echo

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create package structure
echo "Creating package structure..."
mkdir -p "$BUILD_DIR"/{DEBIAN,data/data/com.termux/files/usr/{bin,share/codex/{docs,examples},etc/codex}}

# Copy control files
echo "Creating package metadata..."
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: openssl-tool
Installed-Size: 23552
Maintainer: Android Codex Team <noreply@github.com>
Description: AI-powered coding assistant for Android
 Android Codex brings OpenAI's powerful coding agent directly to Android
 devices with native ARM64 binaries, custom Android PTY implementation,
 and comprehensive debugging support.
Homepage: https://github.com/WangChengYeh/codex_android
EOF

# Create post-installation script
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
echo "Setting up Android Codex..."
mkdir -p ~/.config/codex
if [ ! -f ~/.config/codex/config.toml ]; then
    cp /data/data/com.termux/files/usr/etc/codex/config.toml.example ~/.config/codex/config.toml
fi
if ! grep -q "export CODEX_HOME" ~/.bashrc 2>/dev/null; then
    echo 'export CODEX_HOME=$HOME' >> ~/.bashrc
fi
echo "Android Codex installed! Run 'codex-setup' to configure."
exit 0
EOF

chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# Copy binary and scripts
echo "Copying binaries and scripts..."
cp android_codex_binary "$BUILD_DIR/data/data/com.termux/files/usr/bin/codex"
cp termux-setup.sh "$BUILD_DIR/data/data/com.termux/files/usr/bin/codex-setup"
chmod +x "$BUILD_DIR/data/data/com.termux/files/usr/bin/"*

# Copy documentation
echo "Copying documentation..."
cp ANDROID_BUILD_RUN_GUIDE.md "$BUILD_DIR/data/data/com.termux/files/usr/share/codex/docs/"
cp README.md "$BUILD_DIR/data/data/com.termux/files/usr/share/codex/docs/"

# Copy configuration template
cp config.toml.example "$BUILD_DIR/data/data/com.termux/files/usr/etc/codex/"

# Create examples
echo "Creating usage examples..."
cat > "$BUILD_DIR/data/data/com.termux/files/usr/share/codex/examples/basic_usage.md" << 'EOF'
# Android Codex Examples

## Basic Usage
```bash
# System analysis
codex exec "Analyze this Android system and show hardware info"

# Code generation
codex exec "Create a shell script to monitor system resources"

# File operations (with write permissions)
codex exec --sandbox workspace-write "Create a test configuration file"
```

## Advanced Usage
```bash
# Skip git repo check (useful in non-git directories)
codex exec --skip-git-repo-check "Your prompt here"

# Different sandbox modes
codex exec --sandbox read-only "Safe read-only operations"
codex exec --sandbox workspace-write "Operations that need file access"
```
EOF

# Set permissions
echo "Setting package permissions..."
find "$BUILD_DIR/data" -type d -exec chmod 755 {} \;
find "$BUILD_DIR/data" -type f -exec chmod 644 {} \;
chmod +x "$BUILD_DIR/data/data/com.termux/files/usr/bin/"*

# Build package
echo "Building .deb package..."
cd "$BUILD_DIR"
dpkg-deb --build . "../${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
cd ..

# Verify package
echo "Verifying package..."
dpkg-deb --info "${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo
echo "Package contents:"
dpkg-deb --contents "${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" | head -20

# Package info
PACKAGE_SIZE=$(du -h "${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" | cut -f1)
echo
echo "✅ Package built successfully!"
echo "   File: ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "   Size: $PACKAGE_SIZE"
echo
echo "📦 Installation command:"
echo "   pkg install ./${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo
echo "🚀 After installation, run: codex-setup"