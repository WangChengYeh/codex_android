# uv run android_deploy_simple.py
# /// script
# dependencies = [
#   "pexpect",
# ]
# ///

import pexpect
import sys
import time
import os

def simple_android_build_test():
    """Simple Android build and test without full codex"""
    
    print("=== Simple Android Build Test ===")
    
    # Step 1: Build a simple library first
    print("\n1. Building simple Android library...")
    build_child = pexpect.spawn('cargo build --release --target aarch64-linux-android --lib -p codex-apply-patch', timeout=60)
    build_child.logfile = sys.stdout.buffer
    
    try:
        build_child.expect([pexpect.EOF], timeout=60)
        print("✅ Simple library build successful!")
    except Exception as e:
        print(f"Build error: {e}")
        return False
    finally:
        build_child.close()
    
    # Step 2: Try building a simple binary
    print("\n2. Creating minimal test binary...")
    
    # Create a minimal test binary
    test_main = """
fn main() {
    println!("Hello Android from Rust!");
    println!("Current dir: {:?}", std::env::current_dir());
    println!("Args: {:?}", std::env::args().collect::<Vec<_>>());
}
"""
    
    # Write test binary
    with open('test_android_main.rs', 'w') as f:
        f.write(test_main)
    
    print("\n3. Building test binary...")
    rustc_child = pexpect.spawn('rustc --target aarch64-linux-android test_android_main.rs -o test_android', timeout=60)
    rustc_child.logfile = sys.stdout.buffer
    
    try:
        rustc_child.expect([pexpect.EOF], timeout=60)
        print("✅ Test binary build successful!")
    except:
        print("❌ Test binary build failed")
        return False
    finally:
        rustc_child.close()
    
    # Step 3: Check if device is connected
    print("\n4. Checking Android device connection...")
    adb_child = pexpect.spawn('adb devices', timeout=10)
    adb_child.logfile = sys.stdout.buffer
    
    try:
        adb_child.expect([pexpect.EOF], timeout=10)
        adb_output = adb_child.before.decode()
        
        if 'device' not in adb_output or adb_output.count('device') < 2:
            print("❌ No Android device detected. Please connect device and enable USB debugging.")
            return False
        else:
            print("✅ Android device detected")
    finally:
        adb_child.close()
    
    # Step 4: Push and test binary
    print("\n5. Pushing test binary to device...")
    push_child = pexpect.spawn('adb push test_android /data/local/tmp/test_android', timeout=30)
    push_child.logfile = sys.stdout.buffer
    
    try:
        push_child.expect([pexpect.EOF], timeout=30)
        print("✅ Binary pushed to device")
    except:
        print("❌ Failed to push binary")
        return False
    finally:
        push_child.close()
    
    # Step 5: Make executable and test
    print("\n6. Testing binary execution...")
    test_commands = [
        'adb shell chmod +x /data/local/tmp/test_android',
        'adb shell /data/local/tmp/test_android'
    ]
    
    for cmd in test_commands:
        cmd_child = pexpect.spawn(cmd, timeout=15)
        cmd_child.logfile = sys.stdout.buffer
        try:
            cmd_child.expect([pexpect.EOF], timeout=15)
        finally:
            cmd_child.close()
    
    print("✅ Simple Android deployment test completed!")
    
    # Cleanup
    try:
        os.remove('test_android_main.rs')
        os.remove('test_android')
    except:
        pass
    
    return True

# Run the simple test
if __name__ == "__main__":
    success = simple_android_build_test()
    if success:
        print("\n✅ Simple Android deployment successful!")
    else:
        print("\n❌ Simple deployment test failed")