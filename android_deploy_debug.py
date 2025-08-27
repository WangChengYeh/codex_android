# uv run android_deploy_debug.py
# /// script
# dependencies = [
#   "pexpect",
# ]
# ///

import pexpect
import sys
import time
import os

def android_codex_deploy_debug():
    """Deploy and debug Android Codex using pexpect"""
    
    print("=== Android Codex Deploy & Debug Session ===")
    
    # Step 1: Build Android binary
    print("\n1. Building Android Codex binary...")
    build_child = pexpect.spawn('bash ./build-android.sh', timeout=300)
    build_child.logfile = sys.stdout.buffer
    
    try:
        # Wait for build to complete
        build_index = build_child.expect([
            'Android build completed successfully!',
            'Error:',
            pexpect.TIMEOUT,
            pexpect.EOF
        ], timeout=300)
        
        if build_index == 0:
            print("\n✅ Android build successful!")
        else:
            print("\n❌ Build failed or timed out")
            return False
            
    except Exception as e:
        print(f"Build error: {e}")
        return False
    finally:
        build_child.close()
    
    # Step 2: Check if device is connected
    print("\n2. Checking Android device connection...")
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
    
    # Step 3: Push binary to device
    print("\n3. Pushing codex binary to Android device...")
    push_child = pexpect.spawn('adb push codex-rs/target/aarch64-linux-android/release/codex /data/local/tmp/codex', timeout=60)
    push_child.logfile = sys.stdout.buffer
    
    try:
        push_child.expect([pexpect.EOF], timeout=60)
        print("✅ Binary pushed to device")
    except:
        print("❌ Failed to push binary")
        return False
    finally:
        push_child.close()
    
    # Step 4: Make binary executable
    print("\n4. Making binary executable...")
    chmod_child = pexpect.spawn('adb shell chmod +x /data/local/tmp/codex', timeout=10)
    chmod_child.expect([pexpect.EOF], timeout=10)
    chmod_child.close()
    
    # Step 5: Test basic execution
    print("\n5. Testing basic execution...")
    test_child = pexpect.spawn('adb shell /data/local/tmp/codex --version', timeout=30)
    test_child.logfile = sys.stdout.buffer
    
    try:
        test_child.expect([pexpect.EOF], timeout=30)
        print("✅ Basic execution test completed")
    except:
        print("⚠️ Basic execution may have issues")
    finally:
        test_child.close()
    
    # Step 6: Start lldb debugging session
    print("\n6. Starting lldb debugging session...")
    
    # First, start the binary on device in background
    print("Starting codex on device...")
    device_child = pexpect.spawn('adb shell', timeout=10)
    device_child.expect(['#', '$'], timeout=10)
    device_child.sendline('cd /data/local/tmp')
    device_child.expect(['#', '$'], timeout=5)
    device_child.sendline('./codex --help &')  # Run in background
    device_child.expect(['#', '$'], timeout=10)
    
    # Get the process ID
    device_child.sendline('ps | grep codex')
    device_child.expect(['#', '$'], timeout=5)
    ps_output = device_child.before.decode()
    
    # Extract PID (assuming format: user pid ppid ... command)
    lines = ps_output.strip().split('\n')
    pid = None
    for line in lines:
        if 'codex' in line and './codex' in line:
            parts = line.split()
            if len(parts) >= 2:
                pid = parts[1]  # Second column is usually PID
                break
    
    if pid:
        print(f"✅ Found codex process with PID: {pid}")
        
        # Step 7: Setup lldb
        print("\n7. Setting up lldb debugging...")
        lldb_child = pexpect.spawn('lldb', timeout=30)
        lldb_child.logfile = sys.stdout.buffer
        
        try:
            # Wait for lldb prompt
            lldb_child.expect('(lldb)', timeout=10)
            
            # Connect to remote platform
            print("Connecting to Android platform...")
            lldb_child.sendline('platform select remote-android')
            lldb_child.expect('(lldb)', timeout=10)
            
            # Connect to device (assuming adb is forwarding)
            lldb_child.sendline('platform connect connect://localhost:5555')  # Default adb port
            lldb_child.expect(['(lldb)', 'error:', 'Connected'], timeout=15)
            
            # Attach to process
            print(f"Attaching to PID {pid}...")
            lldb_child.sendline(f'attach -p {pid}')
            lldb_child.expect(['(lldb)', 'error:', 'Process'], timeout=20)
            
            # Set some useful breakpoints
            print("Setting breakpoints...")
            lldb_child.sendline('breakpoint set --name main')
            lldb_child.expect('(lldb)', timeout=10)
            
            lldb_child.sendline('breakpoint set --name panic')
            lldb_child.expect('(lldb)', timeout=10)
            
            # Show current state
            lldb_child.sendline('process status')
            lldb_child.expect('(lldb)', timeout=10)
            
            print("\n✅ lldb debugging session established!")
            print("Common lldb commands:")
            print("- 'c' or 'continue' to resume execution")
            print("- 'bt' for backtrace")
            print("- 'breakpoint list' to see breakpoints")
            print("- 'register read' to see registers")
            print("- 'memory read' to examine memory")
            print("- 'quit' to exit lldb")
            
            # Interactive session
            print("\nEntering interactive lldb session (type 'quit' to exit)...")
            while True:
                try:
                    lldb_child.expect('(lldb)', timeout=1)
                    command = input("(lldb) ")
                    if command.lower() in ['quit', 'exit', 'q']:
                        lldb_child.sendline('quit')
                        break
                    lldb_child.sendline(command)
                except pexpect.TIMEOUT:
                    continue
                except KeyboardInterrupt:
                    print("\nExiting lldb session...")
                    lldb_child.sendline('quit')
                    break
                    
        except Exception as e:
            print(f"lldb error: {e}")
        finally:
            try:
                lldb_child.close()
            except:
                pass
    else:
        print("❌ Could not find codex process PID")
    
    # Cleanup
    try:
        device_child.sendline('killall codex')  # Kill any remaining codex processes
        device_child.expect(['#', '$'], timeout=5)
        device_child.close()
    except:
        pass
    
    return True

# Run the deployment and debugging session
if __name__ == "__main__":
    success = android_codex_deploy_debug()
    if success:
        print("\n✅ Android Codex deploy & debug session completed!")
    else:
        print("\n❌ Session failed - check the logs above")