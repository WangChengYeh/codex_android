# Android Codex CLI 0.25.0 Makefile
# Build system for Android Codex with Termux package creation

.PHONY: all build test package clean install deploy help
.DEFAULT_GOAL := help

# Configuration
RUST_TARGET = aarch64-linux-android
PACKAGE_NAME = codex-android
PACKAGE_VERSION = 0.25.0
PACKAGE_ARCH = aarch64
BUILD_DIR = codex-rs/target/$(RUST_TARGET)/release
PACKAGE_DIR = termux-package-new
DEB_FILE = $(PACKAGE_NAME)-$(PACKAGE_VERSION)-$(PACKAGE_ARCH).deb

# Colors for output
RED = \033[31m
GREEN = \033[32m
YELLOW = \033[33m
BLUE = \033[34m
RESET = \033[0m

# Help target
help: ## Show this help message
	@echo "$(BLUE)Android Codex CLI 0.25.0 Build System$(RESET)"
	@echo "======================================"
	@echo
	@echo "$(GREEN)Available targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo

# Build Android binaries
build: ## Build Android Codex binaries for aarch64
	@echo "$(BLUE)Building Android Codex CLI 0.25.0...$(RESET)"
	@./build-android.sh
	@if [ -f "$(BUILD_DIR)/codex" ] && [ -f "$(BUILD_DIR)/codex-exec" ]; then \
		echo "$(GREEN)✅ Build successful!$(RESET)"; \
		ls -la $(BUILD_DIR)/codex*; \
	else \
		echo "$(RED)❌ Build failed!$(RESET)"; \
		exit 1; \
	fi

# Run tests
test: ## Run tests for Android build
	@echo "$(BLUE)Running Android Codex tests...$(RESET)"
	@cd codex-rs && cargo test --target $(RUST_TARGET) --release
	@echo "$(GREEN)✅ Tests completed!$(RESET)"

# Build Termux package
package: build ## Build Termux .deb package
	@echo "$(BLUE)Creating Termux package...$(RESET)"
	@$(MAKE) clean-package
	@$(MAKE) create-package-structure
	@$(MAKE) copy-binaries
	@$(MAKE) create-control-files
	@$(MAKE) create-scripts
	@$(MAKE) create-docs
	@$(MAKE) build-deb
	@echo "$(GREEN)✅ Package created: $(DEB_FILE)$(RESET)"
	@ls -la $(DEB_FILE)

# Clean build artifacts
clean: ## Clean all build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(RESET)"
	@cd codex-rs && cargo clean
	@rm -rf $(PACKAGE_DIR)
	@rm -f *.deb *.tar.gz debian-binary
	@echo "$(GREEN)✅ Clean completed!$(RESET)"

# Install package to Android device
install: package ## Install package to connected Android device
	@echo "$(BLUE)Installing to Android device...$(RESET)"
	@cp $(DEB_FILE) codex-android_0.0.1_aarch64.deb
	@python3 install_termux_package.py
	@echo "$(GREEN)✅ Installation prepared!$(RESET)"

# Deploy package (build + install)
deploy: ## Build and deploy package to Android device
	@echo "$(BLUE)Building and deploying Android Codex...$(RESET)"
	@$(MAKE) package
	@$(MAKE) install

# Internal targets for package creation
clean-package:
	@rm -rf $(PACKAGE_DIR)
	@rm -f *.tar.gz debian-binary

create-package-structure:
	@echo "  📁 Creating package structure..."
	@mkdir -p $(PACKAGE_DIR)/{DEBIAN,data/data/com.termux/files/usr/{bin,share/codex/{docs,examples},etc/codex}}

copy-binaries:
	@echo "  📦 Copying binaries..."
	@cp $(BUILD_DIR)/codex $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/
	@cp $(BUILD_DIR)/codex-exec $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/

create-control-files:
	@echo "  📋 Creating control files..."
	@echo "Package: $(PACKAGE_NAME)" > $(PACKAGE_DIR)/DEBIAN/control
	@echo "Version: $(PACKAGE_VERSION)" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Architecture: $(PACKAGE_ARCH)" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Maintainer: Android Codex Team" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Depends: bash" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Section: devel" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Priority: optional" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Homepage: https://github.com/WangChengYeh/codex_android" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo "Description: Android Codex CLI $(PACKAGE_VERSION) for Termux" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo " Android port of Codex CLI with custom PTY implementation" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo " and Termux environment integration. Provides full AI-powered" >> $(PACKAGE_DIR)/DEBIAN/control
	@echo " coding assistance directly on Android devices through Termux." >> $(PACKAGE_DIR)/DEBIAN/control

create-scripts:
	@echo "  🔧 Creating setup scripts..."
	@echo '#!/data/data/com.termux/files/usr/bin/bash' > $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/codex-setup
	@echo 'echo "🤖 Setting up Android Codex CLI 0.25.0"' >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/codex-setup
	@echo 'echo "======================================"' >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/codex-setup
	@echo 'mkdir -p ~/.config/codex' >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/codex-setup
	@echo 'chmod +x /data/data/com.termux/files/usr/bin/codex*' >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/codex-setup
	@echo 'echo "✅ Setup complete!"' >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/codex-setup
	@echo '#!/data/data/com.termux/files/usr/bin/bash' > $(PACKAGE_DIR)/DEBIAN/postinst
	@echo 'chmod +x /data/data/com.termux/files/usr/bin/*' >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo 'echo "✅ Android Codex CLI installed!"' >> $(PACKAGE_DIR)/DEBIAN/postinst
	@echo 'exit 0' >> $(PACKAGE_DIR)/DEBIAN/postinst
	@chmod +x $(PACKAGE_DIR)/DEBIAN/postinst $(PACKAGE_DIR)/data/data/com.termux/files/usr/bin/*

create-docs:
	@echo "  📖 Creating documentation..."
	@echo "# Android Codex CLI 0.25.0 Configuration" > $(PACKAGE_DIR)/data/data/com.termux/files/usr/etc/codex/config.toml.example
	@echo "[model]" >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/etc/codex/config.toml.example
	@echo 'name = "claude-3-5-sonnet-20241022"' >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/etc/codex/config.toml.example
	@echo "# Android Codex CLI 0.25.0 - Basic Usage" > $(PACKAGE_DIR)/data/data/com.termux/files/usr/share/codex/examples/basic_usage.md
	@echo "Run: codex exec 'your command here'" >> $(PACKAGE_DIR)/data/data/com.termux/files/usr/share/codex/examples/basic_usage.md
	@cp README.md $(PACKAGE_DIR)/data/data/com.termux/files/usr/share/codex/docs/ 2>/dev/null || true

build-deb:
	@echo "  🏗️  Building .deb package..."
	@dpkg-deb --build $(PACKAGE_DIR) $(DEB_FILE)

# Development targets
dev-build: ## Quick development build without full package
	@echo "$(BLUE)Development build...$(RESET)"
	@cd codex-rs && cargo build --target $(RUST_TARGET)

check: ## Check code without building
	@echo "$(BLUE)Checking code...$(RESET)"
	@cd codex-rs && cargo check --target $(RUST_TARGET)

fmt: ## Format code
	@echo "$(BLUE)Formatting code...$(RESET)"
	@cd codex-rs && cargo fmt

clippy: ## Run clippy linter
	@echo "$(BLUE)Running clippy...$(RESET)"
	@cd codex-rs && cargo clippy --target $(RUST_TARGET)

# Info targets
version: ## Show version information
	@echo "$(BLUE)Version Information:$(RESET)"
	@echo "Package: $(PACKAGE_NAME) $(PACKAGE_VERSION)"
	@echo "Architecture: $(PACKAGE_ARCH)"
	@echo "Target: $(RUST_TARGET)"

status: ## Show build status
	@echo "$(BLUE)Build Status:$(RESET)"
	@echo -n "Android binaries: "
	@if [ -f "$(BUILD_DIR)/codex" ] && [ -f "$(BUILD_DIR)/codex-exec" ]; then \
		echo "$(GREEN)✅ Built$(RESET)"; \
	else \
		echo "$(RED)❌ Not built$(RESET)"; \
	fi
	@echo -n "Termux package: "
	@if [ -f "$(DEB_FILE)" ]; then \
		echo "$(GREEN)✅ Available ($(DEB_FILE))$(RESET)"; \
	else \
		echo "$(RED)❌ Not built$(RESET)"; \
	fi

# All-in-one targets
all: clean build test package ## Clean, build, test, and package
	@echo "$(GREEN)🎉 All tasks completed successfully!$(RESET)"

quick: build package ## Quick build and package (skip tests)
	@echo "$(GREEN)🚀 Quick build completed!$(RESET)"