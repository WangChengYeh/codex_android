#!/bin/bash
# Android Codex Setup Script
# Deploys and configures Android Codex with proper environment

echo "=== Android Codex Setup ==="

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device found. Please connect device with USB debugging enabled."
    exit 1
fi

echo "✅ Android device detected"

# Deploy binary
echo "📱 Deploying Android Codex binary..."
adb push android_codex_binary /data/local/tmp/codex
adb shell chmod +x /data/local/tmp/codex

# Test deployment
echo "🧪 Testing deployment..."
if adb shell "/data/local/tmp/codex --version" | grep -q "codex-cli"; then
    echo "✅ Deployment successful!"
else
    echo "❌ Deployment failed"
    exit 1
fi

# Create environment setup helper
echo "⚙️ Creating environment setup script on device..."
adb shell "cat > /data/local/tmp/setup_env.sh << 'EOF'
#!/bin/sh
# Android Codex Environment Setup
# Source this before using Codex: . /data/local/tmp/setup_env.sh

# CRITICAL: Set HOME to writable directory (fixes rollout recorder error)
export HOME=/data/local/tmp

# Set API key (replace with your actual key)
export OPENAI_API_KEY=\${OPENAI_API_KEY:-your_api_key_here}

# Navigate to binary location
cd /data/local/tmp

echo \"✅ Android Codex environment ready!\"
echo \"HOME: \$HOME\"
echo \"API Key: \${OPENAI_API_KEY:0:20}...\"
echo \"\"
echo \"Usage examples:\"
echo \"  ./codex --help\"
echo \"  ./codex exec --skip-git-repo-check 'Your prompt here'\"
EOF"

adb shell chmod +x /data/local/tmp/setup_env.sh

echo ""
echo "🎉 Android Codex setup complete!"
echo ""
echo "📋 To use on Android device:"
echo "1. adb shell"
echo "2. . /data/local/tmp/setup_env.sh    # Source environment"
echo "3. export OPENAI_API_KEY=your_key    # Set your actual API key"
echo "4. ./codex exec --skip-git-repo-check 'Your prompt'"
echo ""
echo "🔧 Key files on device:"
echo "  /data/local/tmp/codex          - Main binary (23MB)"
echo "  /data/local/tmp/setup_env.sh   - Environment setup script"
echo ""
echo "💡 The HOME=/data/local/tmp setting is CRITICAL to prevent rollout recorder errors!"