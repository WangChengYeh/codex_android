#!/usr/bin/env python3
"""
MCP Pexpect Script: Install Android Codex Termux Package
Automates the installation of android-codex-cli-0.25.0-aarch64.deb on Android device
"""

import pexpect
import sys
import time

def install_termux_package():
    print("=== Installing Android Codex Termux Package ===")
    print()
    
    # Step 1: Push package to Android device
    print("📦 Step 1: Pushing .deb package to Android device...")
    push_cmd = 'adb push android-codex-cli-0.25.0-aarch64.deb /data/local/tmp/'
    
    try:
        child = pexpect.spawn(push_cmd, timeout=60)
        child.logfile_read = sys.stdout.buffer
        child.expect(pexpect.EOF)
        child.wait()
        
        if child.exitstatus == 0:
            print("✅ Package pushed successfully to /data/local/tmp/")
        else:
            print("❌ Failed to push package")
            return False
            
    except Exception as e:
        print(f"❌ Error pushing package: {e}")
        return False
    
    print()
    
    # Step 2: Connect to Android shell and install in Termux
    print("📱 Step 2: Connecting to Android device...")
    
    try:
        # Start ADB shell
        child = pexpect.spawn('adb shell', timeout=30)
        child.logfile_read = sys.stdout.buffer
        
        # Wait for shell prompt
        child.expect(['#', '$'], timeout=10)
        print("✅ Connected to Android shell")
        
        # Check if Termux is installed
        print("\n🔍 Checking Termux installation...")
        child.sendline('pm list packages | grep termux')
        child.expect(['#', '$'], timeout=5)
        
        # Switch to Termux if available, or use regular installation
        print("\n📦 Step 3: Installing Termux package...")
        
        # Copy package to accessible location
        child.sendline('cp /data/local/tmp/android-codex-cli-0.25.0-aarch64.deb /sdcard/')
        child.expect(['#', '$'], timeout=10)
        
        print("✅ Package copied to /sdcard/ for Termux access")
        print()
        print("📋 Manual Installation Instructions:")
        print("   1. Open Termux on your Android device")
        print("   2. Run: cd /sdcard")
        print("   3. Run: pkg install ./android-codex-cli-0.25.0-aarch64.deb")
        print("   4. Run: codex-setup")
        print("   5. Set your API key when prompted")
        print("   6. Test with: codex exec 'echo hello world'")
        print()
        
        # Try to launch Termux directly if possible
        print("🚀 Attempting to launch Termux for installation...")
        child.sendline('am start -n com.termux/.HomeActivity')
        child.expect(['#', '$'], timeout=5)
        
        print("✅ Termux should now be launching...")
        print()
        
        child.sendline('exit')
        child.expect(pexpect.EOF)
        
        return True
        
    except Exception as e:
        print(f"❌ Error during installation: {e}")
        return False

def create_termux_install_script():
    """Create a script for easy Termux installation"""
    print("📝 Creating Termux installation script...")
    
    script_content = '''#!/data/data/com.termux/files/usr/bin/bash
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
'''
    
    try:
        # Push the installation script
        with open('termux_install.sh', 'w') as f:
            f.write(script_content)
            
        push_cmd = 'adb push termux_install.sh /sdcard/'
        child = pexpect.spawn(push_cmd, timeout=30)
        child.logfile_read = sys.stdout.buffer
        child.expect(pexpect.EOF)
        child.wait()
        
        print("✅ Installation script created at /sdcard/termux_install.sh")
        print("   Run in Termux: bash /sdcard/termux_install.sh")
        
        return True
        
    except Exception as e:
        print(f"❌ Error creating install script: {e}")
        return False

def main():
    print("🤖 Android Codex Termux Package Installer")
    print("=========================================")
    print()
    
    # Check ADB connection
    try:
        child = pexpect.spawn('adb devices', timeout=10)
        child.logfile_read = sys.stdout.buffer
        child.expect(pexpect.EOF)
        child.wait()
        
        if child.exitstatus != 0:
            print("❌ ADB not working or no device connected")
            return False
            
    except Exception as e:
        print(f"❌ Error checking ADB: {e}")
        return False
    
    # Install package
    success = install_termux_package()
    
    if success:
        # Create helper script
        create_termux_install_script()
        
        print("🎉 Package installation prepared successfully!")
        print()
        print("📱 Next Steps:")
        print("   1. Open Termux on your Android device")
        print("   2. Run: bash /sdcard/termux_install.sh")
        print("   3. Follow the setup prompts")
        print("   4. Start using: codex exec 'Your prompt'")
        print()
        
        return True
    else:
        print("❌ Installation failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)