#!/bin/bash

# Minimal script to test if /dev/pts works on Android

echo "Testing /dev/pts functionality on Android..."
echo

# Test 1: Check if /dev/pts directory exists
echo "1. Checking if /dev/pts exists:"
if [ -d "/dev/pts" ]; then
    echo "   ✓ /dev/pts directory exists"
else
    echo "   ✗ /dev/pts directory does not exist"
    exit 1
fi

# Test 2: Check if /dev/pts is mounted
echo "2. Checking /dev/pts mount:"
if mount | grep -q "/dev/pts"; then
    echo "   ✓ /dev/pts is mounted"
    mount | grep "/dev/pts"
else
    echo "   ✗ /dev/pts is not mounted"
fi

# Test 3: List contents of /dev/pts
echo "3. Contents of /dev/pts:"
ls -la /dev/pts/ 2>/dev/null || echo "   ✗ Cannot list /dev/pts contents"

# Test 4: Check if ptmx exists
echo "4. Checking for /dev/ptmx:"
if [ -e "/dev/ptmx" ]; then
    echo "   ✓ /dev/ptmx exists"
    ls -la /dev/ptmx
else
    echo "   ✗ /dev/ptmx does not exist"
fi

# Test 5: Try to open a pseudo-terminal
echo "5. Testing pseudo-terminal creation:"
if command -v script >/dev/null 2>&1; then
    echo "   Testing with 'script' command..."
    timeout 2s script -qc "echo 'PTS test successful'" /dev/null 2>/dev/null && echo "   ✓ script command works" || echo "   ✗ script command failed"
else
    echo "   'script' command not available"
fi

# Test 6: Check permissions
echo "6. Checking /dev/pts permissions:"
stat /dev/pts 2>/dev/null | grep "Access:" || echo "   Cannot get /dev/pts permissions"

echo
echo "Test complete."