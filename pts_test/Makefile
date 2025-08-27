# Android NDK Configuration
ANDROID_NDK_HOME ?= /Users/wangchengye/Library/Android/sdk/ndk/27.2.12479018
NDK_HOST_TAG = darwin-x86_64
TARGET_ARCH = aarch64
API_LEVEL = 21

# NDK Toolchain
TOOLCHAIN = $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(NDK_HOST_TAG)
CC = $(TOOLCHAIN)/bin/$(TARGET_ARCH)-linux-android$(API_LEVEL)-clang
STRIP = $(TOOLCHAIN)/bin/llvm-strip

CFLAGS = -Wall -Wextra -std=c99 -static
TARGET = pts_test
SOURCE = pts_test.c

# Default target
all: $(TARGET)

# Build the test program
$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)
	$(STRIP) $(TARGET)

# Clean up build artifacts
clean:
	rm -f $(TARGET)

# Run the test
test: $(TARGET)
	./$(TARGET)

# Install and run on Android device
install: $(TARGET)
	adb push $(TARGET) /data/local/tmp/
	adb shell chmod 755 /data/local/tmp/$(TARGET)

# Run the test on Android device
run: install
	adb shell /data/local/tmp/$(TARGET)

# Show build info
info:
	@echo "Android NDK: $(ANDROID_NDK_HOME)"
	@echo "Toolchain: $(TOOLCHAIN)" 
	@echo "Compiler: $(CC)"
	@echo "Target: $(TARGET_ARCH) API $(API_LEVEL)"

.PHONY: all clean test install run info