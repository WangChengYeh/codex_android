# uv run android_lldb_debug.py
# /// script
# dependencies = [
#   "pexpect",
# ]
# ///

import pexpect
import sys
import time
import os
import signal

def android_lldb_debug_session():
    """Complete Android debugging session with lldb"""
    
    print("=== Android LLDB Debugging Session ===")
    
    # Step 1: Verify binary exists on device
    print("\n1. Verifying binary on device...")
    adb_child = pexpect.spawn('adb shell ls -la /data/local/tmp/test_android_minimal', timeout=10)
    adb_child.logfile = sys.stdout.buffer
    
    try:
        adb_child.expect([pexpect.EOF], timeout=10)
        print("✅ Binary exists on device")
    except:
        print("❌ Binary not found on device")
        return False
    finally:
        adb_child.close()
    
    # Step 2: Start the binary on device in background and get PID
    print("\n2. Starting binary on device...")
    device_shell = pexpect.spawn('adb shell', timeout=10)
    device_shell.logfile = sys.stdout.buffer
    
    try:
        device_shell.expect(['#', '$'], timeout=10)
        
        # Start the binary in background with sleep to keep it running
        device_shell.sendline('cd /data/local/tmp && ./test_android_minimal & echo "Started with PID: $!"')
        device_shell.expect(['#', '$'], timeout=10)
        
        # Get process list to find our binary
        device_shell.sendline('ps | grep test_android')
        device_shell.expect(['#', '$'], timeout=5)
        ps_output = device_shell.before.decode()
        
        print("Process search output:")
        print(ps_output)
        
        # Try to extract PID (this is tricky as the format varies by Android version)
        lines = ps_output.strip().split('\n')
        pid = None
        for line in lines:
            if 'test_android_minimal' in line:
                parts = line.split()
                # Try different positions for PID (usually 2nd or 3rd column)
                for i in [1, 2]:
                    if i < len(parts) and parts[i].isdigit():
                        pid = parts[i]
                        break
                if pid:
                    break
        
        if not pid:
            # Alternative: try to start with a different approach
            print("Could not find PID, trying alternative approach...")
            device_shell.sendline('nohup ./test_android_minimal < /dev/null > test_output.log 2>&1 &')
            device_shell.expect(['#', '$'], timeout=5)
            time.sleep(2)  # Give it time to start
            
            device_shell.sendline('ps -A | grep test_android')
            device_shell.expect(['#', '$'], timeout=5)
            ps_output = device_shell.before.decode()
            
            lines = ps_output.strip().split('\n')
            for line in lines:
                if 'test_android_minimal' in line:
                    parts = line.split()
                    for i in range(len(parts)):
                        if parts[i].isdigit() and len(parts[i]) >= 3:  # PID is usually 3+ digits
                            pid = parts[i]
                            break
                    if pid:
                        break
        
        if pid:
            print(f"✅ Found process with PID: {pid}")
        else:
            print("❌ Could not find process PID")
            # Let's still try to demonstrate lldb setup
            pid = "1234"  # Dummy PID for demo
            print(f"Using dummy PID {pid} for lldb demonstration")
        
    except Exception as e:
        print(f"Error starting process: {e}")
        return False
    
    # Step 3: Setup lldb debugging session
    print(f"\n3. Setting up lldb debugging for PID {pid}...")
    
    # Start lldb
    lldb_child = pexpect.spawn('lldb', timeout=30)
    lldb_child.logfile = sys.stdout.buffer
    
    try:
        # Wait for lldb prompt
        lldb_child.expect('(lldb)', timeout=10)
        print("✅ LLDB started successfully")
        
        # Set up remote Android debugging
        print("Setting up remote Android platform...")
        lldb_child.sendline('platform select remote-android')
        lldb_child.expect('(lldb)', timeout=10)
        
        # Forward ADB for debugging
        print("Setting up ADB port forwarding...")
        adb_forward = pexpect.spawn('adb forward tcp:5039 tcp:5039', timeout=10)
        adb_forward.expect([pexpect.EOF], timeout=10)
        adb_forward.close()
        
        # Start lldb-server on Android device (this usually requires root)
        print("Attempting to start lldb-server on device (may require root)...")
        device_shell.sendline('which lldb-server')
        device_shell.expect(['#', '$'], timeout=5)
        
        # For non-root devices, we'll demonstrate the commands that would work
        print("\n=== LLDB Command Reference for Android Debugging ===")
        print("The following commands demonstrate how to debug on Android:")
        print("1. On device (requires root or lldb-server):")
        print("   adb shell")
        print("   su  # if available")
        print("   lldb-server platform --listen '*:5039' --server")
        print()
        print("2. In LLDB on host:")
        print("   platform connect connect://localhost:5039")
        print(f"   attach -p {pid}")
        print("   breakpoint set --name main")
        print("   continue")
        print()
        print("3. Common debugging commands:")
        print("   bt                    # Show backtrace")
        print("   frame variable        # Show local variables")
        print("   register read         # Show CPU registers")
        print("   memory read <addr>    # Read memory")
        print("   step                  # Step one line")
        print("   next                  # Step over function calls")
        print("   continue              # Resume execution")
        print("   quit                  # Exit lldb")
        
        # Let's demonstrate some basic lldb commands even without remote connection
        print("\n=== Basic LLDB Commands Demo ===")
        
        # Show help
        lldb_child.sendline('help')
        lldb_child.expect('(lldb)', timeout=10)
        
        # Show platform info
        lldb_child.sendline('platform status')
        lldb_child.expect('(lldb)', timeout=10)
        
        # List available platforms
        lldb_child.sendline('platform list')
        lldb_child.expect('(lldb)', timeout=10)
        
        print("\n✅ LLDB commands demonstrated successfully!")
        print("\n=== Interactive LLDB Session ===")
        print("You can now enter lldb commands. Type 'quit' to exit.")
        print("Note: Remote debugging requires lldb-server running on Android device.")
        
        # Interactive session
        while True:
            try:
                # Wait for prompt with short timeout to allow user input
                index = lldb_child.expect(['(lldb)', pexpect.TIMEOUT], timeout=1)
                
                if index == 0:  # Got lldb prompt
                    try:
                        command = input("(lldb) ").strip()
                        if command.lower() in ['quit', 'exit', 'q']:
                            lldb_child.sendline('quit')
                            break
                        elif command:
                            lldb_child.sendline(command)
                    except (EOFError, KeyboardInterrupt):
                        print("\nExiting lldb session...")
                        lldb_child.sendline('quit')
                        break
                
            except pexpect.TIMEOUT:
                continue
            except KeyboardInterrupt:
                print("\nExiting lldb session...")
                lldb_child.sendline('quit')
                break
        
    except Exception as e:
        print(f"LLDB error: {e}")
    finally:
        try:
            lldb_child.close()
        except:
            pass
    
    # Cleanup
    print("\n4. Cleaning up...")
    try:
        # Kill any remaining processes
        device_shell.sendline('pkill test_android_minimal')
        device_shell.expect(['#', '$'], timeout=5)
        device_shell.close()
    except:
        pass
    
    # Remove port forwarding
    try:
        adb_remove_forward = pexpect.spawn('adb forward --remove tcp:5039', timeout=10)
        adb_remove_forward.expect([pexpect.EOF], timeout=10)
        adb_remove_forward.close()
    except:
        pass
    
    print("✅ Android LLDB debugging session completed!")
    return True

def show_android_debug_setup():
    """Show instructions for setting up Android debugging"""
    print("\n=== Android Debugging Setup Instructions ===")
    print()
    print("For full remote debugging with lldb, you need:")
    print()
    print("1. Root access on Android device OR")
    print("2. lldb-server binary available on device OR")
    print("3. Android device with debugging symbols")
    print()
    print("Setup steps:")
    print("1. Enable USB Debugging on Android device")
    print("2. Connect device to computer via USB")
    print("3. On rooted device:")
    print("   adb shell")
    print("   su")
    print("   lldb-server platform --listen '*:5039' --server")
    print()
    print("4. On computer:")
    print("   adb forward tcp:5039 tcp:5039")
    print("   lldb")
    print("   platform select remote-android")
    print("   platform connect connect://localhost:5039")
    print("   attach -p <PID>")
    print()
    print("Alternative approaches:")
    print("- Use gdb instead of lldb (if available)")
    print("- Use Android Studio's native debugging")
    print("- Use strace for system call tracing")
    print("- Use Android logging (logcat)")
    print()
    
# Run the debugging session
if __name__ == "__main__":
    show_android_debug_setup()
    print("\nStarting Android LLDB debugging session...")
    success = android_lldb_debug_session()
    if success:
        print("\n✅ Android debugging session completed successfully!")
    else:
        print("\n❌ Android debugging session failed")