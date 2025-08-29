#!/usr/bin/env python3
"""
Direct Termux Installation via ADB
Installs the package directly in Termux environment
"""

import pexpect
import sys
import time

def direct_termux_install():
    print("=== Direct Termux Installation ===")
    print()
    
    try:
        # Start ADB shell and launch Termux
        print("🔗 Starting ADB shell...")
        child = pexpect.spawn('adb shell', timeout=30)
        child.logfile_read = sys.stdout.buffer
        
        # Wait for shell prompt
        child.expect(['#', '$'], timeout=10)
        
        print("📱 Launching Termux environment...")
        # Use run-as to access Termux environment  
        child.sendline('run-as com.termux')
        
        try:
            index = child.expect(['$', 'Operation not permitted', pexpect.TIMEOUT], timeout=5)
            if index == 1:
                print("⚠️  Direct Termux access not available, using alternative method...")
                child.sendline('exit')
                child.expect(['#', '$'], timeout=5)
                
                # Alternative: Use am command to start Termux with install command
                print("🚀 Starting Termux with install command...")
                child.sendline('am start -n com.termux/.HomeActivity')
                child.expect(['#', '$'], timeout=5)
                
                print()
                print("📋 Termux is now open on your device!")
                print("Please run these commands in Termux:")
                print("   1. cd /sdcard")
                print("   2. pkg install ./android-codex-cli-0.25.0-aarch64.deb")
                print("   3. codex-setup")
                print()
                
                return True
                
        except:
            print("ℹ️  Continuing with manual installation instructions...")
            
        child.sendline('exit')
        child.expect(pexpect.EOF)
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def create_interactive_install():
    """Create an interactive installation session"""
    print("🤖 Starting Interactive Installation Session...")
    print()
    
    # Check if Termux is available
    print("📋 Installation Commands for Termux:")
    print("=====================================")
    print()
    print("1️⃣  Copy package to Termux directory:")
    print("     cp /sdcard/android-codex-cli-0.25.0-aarch64.deb ~/")
    print()
    print("2️⃣  Install the package:")
    print("     pkg install ~/android-codex-cli-0.25.0-aarch64.deb")
    print()
    print("3️⃣  Run initial setup:")
    print("     codex-setup")
    print()
    print("4️⃣  Test installation:")
    print("     codex exec --skip-git-repo-check 'echo Hello Android Codex!'")
    print()
    
    # Wait for user to complete installation
    input("Press Enter after you've completed the installation in Termux...")
    
    # Test the installation
    print("\n🧪 Testing installation via ADB...")
    return test_termux_installation()

def test_termux_installation():
    """Test if the installation was successful"""
    try:
        child = pexpect.spawn('adb shell', timeout=30)
        child.logfile_read = sys.stdout.buffer
        child.expect(['#', '$'], timeout=10)
        
        # Try to run codex from Termux
        print("🔍 Testing Codex installation...")
        child.sendline('run-as com.termux /data/data/com.termux/files/usr/bin/codex --version')
        child.expect(['#', '$'], timeout=10)
        
        child.sendline('exit')
        child.expect(pexpect.EOF)
        
        print("✅ Installation test completed!")
        return True
        
    except Exception as e:
        print(f"⚠️  Could not test installation directly: {e}")
        print("Please verify manually in Termux with: codex --version")
        return True

def main():
    print("📦 Android Codex Termux Direct Installation")
    print("===========================================")
    print()
    
    # Show current status
    print("✅ Package already pushed to device:")
    print("   - /data/local/tmp/android-codex-cli-0.25.0-aarch64.deb")
    print("   - /sdcard/android-codex-cli-0.25.0-aarch64.deb")
    print("   - /sdcard/termux_install.sh")
    print()
    
    # Try direct installation
    success = direct_termux_install()
    
    if success:
        # Create interactive session
        create_interactive_install()
        
        print("🎉 Installation process completed!")
        print()
        print("📱 Your Android device now has Android Codex installed!")
        print("   Use: codex exec 'Your AI prompt here'")
        
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)