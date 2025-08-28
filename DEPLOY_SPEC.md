# Android Codex Deployment Specification

This document outlines deployment strategies for Android Codex, including Termux package creation, APK packaging, and distribution methods.

## 📦 Deployment Options

### 1. Termux Package (Recommended)
### 2. Standalone APK
### 3. Direct Binary Deployment
### 4. Docker Container for Android

---

## 🏗️ Termux Package Deployment

### Package Overview
- **Package Name**: `codex-android`
- **Version**: `0.0.1`
- **Architecture**: `aarch64` (primary), `arm`, `x86_64`, `i686`
- **Dependencies**: None (statically linked)
- **Size**: ~23MB compressed

### Directory Structure
```
$PREFIX/
├── bin/
│   ├── codex                    # Main binary
│   └── codex-setup             # Environment setup script
├── share/
│   └── codex/
│       ├── examples/           # Usage examples
│       ├── docs/              # Documentation
│       └── templates/         # Prompt templates
└── etc/
    └── codex/
        └── config.toml.example # Configuration template
```

### Package Dependencies
```bash
# Required Termux packages
pkg install openssl-tool  # For certificate handling
pkg install git          # For git integration
pkg install python       # For advanced scripts (optional)
```

### Installation Command
```bash
# Future Termux installation
pkg install codex-android

# Or from our repository
pkg install -f ./codex-android_0.0.1_aarch64.deb
```

---

## 📋 Termux Package Build Process

### 1. Create Package Structure
```bash
# Create Termux package directory structure
mkdir -p termux-package/{DEBIAN,data/data/com.termux/files/usr}
cd termux-package
```

### 2. Package Control File
Create `DEBIAN/control`:
```
Package: codex-android
Version: 0.0.1
Section: utils
Priority: optional
Architecture: aarch64
Depends: openssl-tool
Installed-Size: 23552
Maintainer: Android Codex Team <noreply@github.com>
Description: AI-powered coding assistant for Android
 Android Codex brings OpenAI's powerful coding agent directly to Android
 devices with native ARM64 binaries, custom Android PTY implementation,
 and comprehensive debugging support.
 .
 Features:
  - Native ARM64 performance
  - GPT-5 integration with reasoning
  - System analysis and code generation
  - MCP pexpect automation support
  - Complete Android environment compatibility
Homepage: https://github.com/WangChengYeh/codex_android
```

### 3. Pre/Post Installation Scripts

**DEBIAN/postinst:**
```bash
#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "Setting up Android Codex..."

# Set up proper HOME for Codex (critical fix)
if ! grep -q "export CODEX_HOME" ~/.bashrc 2>/dev/null; then
    echo 'export CODEX_HOME=$HOME' >> ~/.bashrc
fi

# Create config directory
mkdir -p ~/.config/codex

# Copy example config if it doesn't exist
if [ ! -f ~/.config/codex/config.toml ]; then
    cp /data/data/com.termux/files/usr/etc/codex/config.toml.example ~/.config/codex/config.toml
fi

echo "Android Codex installed successfully!"
echo "Run 'codex-setup' to configure your API keys"
echo "Then use: codex exec 'Your prompt here'"

exit 0
```

**DEBIAN/prerm:**
```bash
#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "Removing Android Codex..."
# Cleanup can be added here if needed
exit 0
```

### 4. Package Content Setup
```bash
# Copy binary
mkdir -p data/data/com.termux/files/usr/bin
cp android_codex_binary data/data/com.termux/files/usr/bin/codex
chmod +x data/data/com.termux/files/usr/bin/codex

# Copy setup script
cp termux-setup.sh data/data/com.termux/files/usr/bin/codex-setup
chmod +x data/data/com.termux/files/usr/bin/codex-setup

# Copy documentation
mkdir -p data/data/com.termux/files/usr/share/codex/docs
cp ANDROID_BUILD_RUN_GUIDE.md data/data/com.termux/files/usr/share/codex/docs/
cp README.md data/data/com.termux/files/usr/share/codex/docs/

# Copy config template
mkdir -p data/data/com.termux/files/usr/etc/codex
cp config.toml.example data/data/com.termux/files/usr/etc/codex/
```

### 5. Build Package
```bash
# Set permissions
chmod 755 DEBIAN/postinst DEBIAN/prerm
find data -type d -exec chmod 755 {} \;
find data -type f -exec chmod 644 {} \;
chmod +x data/data/com.termux/files/usr/bin/*

# Build .deb package
dpkg-deb --build . codex-android_0.0.1_aarch64.deb

# Verify package
dpkg-deb --info codex-android_0.0.1_aarch64.deb
dpkg-deb --contents codex-android_0.0.1_aarch64.deb
```

---

## 🔧 Termux Setup Script

Create `termux-setup.sh`:
```bash
#!/data/data/com.termux/files/usr/bin/bash
# Termux Android Codex Setup Script

set -e

echo "=== Android Codex Setup for Termux ==="
echo

# Check if we're in Termux
if [ "$PREFIX" != "/data/data/com.termux/files/usr" ]; then
    echo "Warning: This script is designed for Termux"
    echo "Current PREFIX: $PREFIX"
    echo "Expected: /data/data/com.termux/files/usr"
fi

# Set up environment variables
echo "Setting up environment..."

# Critical: Set HOME for Android Codex (prevents rollout recorder error)
export CODEX_HOME="$HOME"
export TMPDIR="$PREFIX/tmp"

# Create necessary directories
mkdir -p "$HOME/.config/codex"
mkdir -p "$PREFIX/tmp"

echo "Environment configured:"
echo "  HOME: $HOME"
echo "  PREFIX: $PREFIX" 
echo "  CODEX_HOME: $CODEX_HOME"
echo

# API Key setup
echo "API Key Configuration:"
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY not set"
    echo "Please set your API key:"
    echo "  export OPENAI_API_KEY='your-api-key-here'"
    echo "  echo 'export OPENAI_API_KEY=\"your-api-key-here\"' >> ~/.bashrc"
    echo
else
    echo "✅ OPENAI_API_KEY configured (${OPENAI_API_KEY:0:20}...)"
    echo
fi

# Test installation
echo "Testing Android Codex installation..."
if command -v codex >/dev/null 2>&1; then
    echo "✅ codex command available"
    
    # Test version
    VERSION=$(codex --version 2>/dev/null || echo "unknown")
    echo "   Version: $VERSION"
    
    # Test basic functionality (if API key is set)
    if [ -n "$OPENAI_API_KEY" ]; then
        echo "🧪 Testing basic functionality..."
        if timeout 10s codex exec --skip-git-repo-check "echo hello world" >/dev/null 2>&1; then
            echo "✅ Basic functionality test passed"
        else
            echo "⚠️  Basic functionality test failed (this may be normal without internet)"
        fi
    fi
else
    echo "❌ codex command not found"
    exit 1
fi

echo
echo "📚 Documentation:"
echo "  Local docs: $PREFIX/share/codex/docs/"
echo "  Quick help: codex --help"
echo
echo "🚀 Usage Examples:"
echo "  codex exec 'Analyze this Android system'"
echo "  codex exec 'Create a shell script to check memory usage'"
echo "  codex exec --sandbox workspace-write 'Create a test file'"
echo
echo "🎉 Android Codex setup complete!"
echo "You can now use 'codex' command in Termux!"
```

---

## 📦 Package Configuration Template

Create `config.toml.example`:
```toml
# Android Codex Configuration Template
# Copy to ~/.config/codex/config.toml and customize

[general]
# Model configuration
model = "gpt-5"
provider = "openai"

# Sandbox mode: read-only, workspace-write, or custom
sandbox = "read-only"

# Approval mode: never, always, or selective  
approval = "never"

# Reasoning effort: low, medium, high
reasoning_effort = "medium"

[android]
# Android-specific settings
home_directory = "$HOME"
temp_directory = "$TMPDIR"

# Skip git repo check by default (useful in Termux)
skip_git_repo_check = true

[paths]
# Termux-specific paths
binary_path = "/data/data/com.termux/files/usr/bin/codex"
config_path = "/data/data/com.termux/files/usr/etc/codex"
docs_path = "/data/data/com.termux/files/usr/share/codex/docs"

[logging]
# Log level: debug, info, warn, error
level = "info"

# Log to file (optional)
# file = "~/.config/codex/codex.log"
```

---

## 🛠️ Build Automation Script

Create `build-termux-package.sh`:
```bash
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
```

---

## 📋 Deployment Checklist

### Pre-deployment
- [ ] **Binary tested** on target Android architecture
- [ ] **Dependencies identified** and available in Termux
- [ ] **Configuration template** created and tested
- [ ] **Setup script** handles all environment configuration
- [ ] **Documentation** included and accessible
- [ ] **Examples** created for common use cases

### Package Building  
- [ ] **Control file** with correct metadata
- [ ] **Post-install script** sets up environment properly
- [ ] **File permissions** correctly set
- [ ] **Package structure** follows Termux conventions
- [ ] **Package size** optimized (compressed ~8-10MB target)

### Testing
- [ ] **Fresh Termux install** package installation test
- [ ] **API key configuration** workflow tested
- [ ] **Basic functionality** verified after install
- [ ] **Documentation accessibility** confirmed
- [ ] **Uninstall process** tested

### Distribution
- [ ] **GitHub releases** page with package downloads
- [ ] **Installation instructions** in README
- [ ] **Termux community** repository submission (future)
- [ ] **Version numbering** scheme established

---

## 🚀 Future Enhancements

### Multi-Architecture Support
```bash
# Build packages for all Android architectures
./build-termux-package.sh aarch64  # ARM64 (primary)
./build-termux-package.sh arm      # ARM32 (older devices)  
./build-termux-package.sh x86_64   # x86_64 emulators
./build-termux-package.sh i686     # x86 (rare)
```

### Repository Integration
- Submit to official Termux package repository
- Create custom APT repository for updates
- Automated CI/CD for package building
- Version update notifications

### Enhanced Features
- Plugin system for extensions
- Configuration GUI for Termux
- Integration with Termux:API
- Battery optimization settings

**Android Codex Termux package provides the easiest installation method for Android users! 📱✨**