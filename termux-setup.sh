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