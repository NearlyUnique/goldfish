# Configuration
EMULATOR_NAME := goldfish_emulator
APK_PATH := build/app/outputs/flutter-apk/app-release.apk
PACKAGE_NAME := dev.goldfish.app
MAIN_ACTIVITY := $(PACKAGE_NAME)/.MainActivity
COVERAGE_PATH := coverage/lcov.info

# Source directories and files
LIB_DIR := lib
TEST_DIR := test
PUBSPEC := pubspec.yaml
ANDROID_DIR := android

# Test files
TEST_FILES := $(shell find $(TEST_DIR) -name '*.dart' 2>/dev/null)
BOOTSTRAP_TEST := test/bootstrap_test.dart

# Source files (for dependency tracking)
SOURCE_FILES := $(shell find $(LIB_DIR) -name '*.dart' 2>/dev/null)

# Phony targets (always execute, don't produce files)
.PHONY: help clean em_launch em_run test_watch lint audit audit-osv audit-dep

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Build target - only rebuilds if sources changed or APK doesn't exist
$(APK_PATH): $(PUBSPEC) $(SOURCE_FILES) $(ANDROID_DIR)
	@echo "Building release APK..."
	@flutter build apk --release
	@echo "APK built at: $(APK_PATH)"

build: $(APK_PATH) ## Build release APK

# Install depends on APK file
install: $(APK_PATH) ## Install APK on connected device/emulator
	@echo "Installing APK..."
	@if adb devices | grep -q "device$$"; then \
		adb install -r $(APK_PATH); \
		echo "APK installed successfully"; \
	else \
		echo "Error: No device/emulator connected. Run 'make em_launch' first."; \
		exit 1; \
	fi

# Deploy depends on APK file
em_deploy: $(APK_PATH) ## Build and deploy APK to emulator
	@echo "Deploying to emulator..."
	@if adb devices | grep -q "device$$"; then \
		adb install -r $(APK_PATH); \
		echo "APK deployed to emulator"; \
		adb shell am start -n $(MAIN_ACTIVITY); \
		echo "App launched"; \
	else \
		echo "Error: No emulator connected. Run 'make em_launch' first."; \
		exit 1; \
	fi

em_launch: ## Launch the emulator
	@echo "Launching emulator: $(EMULATOR_NAME)"
	@flutter emulators --launch $(EMULATOR_NAME)

em_run: ## Run app on emulator (builds and installs automatically)
	@echo "Running app on emulator..."
	@flutter run

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@flutter clean
	@rm -f $(COVERAGE_PATH)
	@echo "Clean complete"

# Test targets - depend on test files and source files
test: $(TEST_FILES) $(SOURCE_FILES) ## Run all tests
	@echo "Running all tests..."
	@flutter test
	@echo "Tests completed"

test_bootstrap: $(BOOTSTRAP_TEST) $(SOURCE_FILES) ## Run bootstrap test only
	@echo "Running bootstrap test..."
	@flutter test $(BOOTSTRAP_TEST)
	@echo "Bootstrap test completed"

test_watch: ## Run tests in watch mode
	@echo "Running tests in watch mode (press 'q' to quit)..."
	@flutter test --watch

lint: $(SOURCE_FILES) ## Run lint/analyze on code
	@echo "Running lint/analyze..."
	@flutter analyze
	@echo "Lint completed"

# Coverage depends on test files and produces coverage file
$(COVERAGE_PATH): $(TEST_FILES) $(SOURCE_FILES)
	@echo "Running tests with coverage..."
	@flutter test --coverage
	@echo "Coverage report generated at: $(COVERAGE_PATH)"

test_coverage: $(COVERAGE_PATH) ## Run tests with coverage report

# Security audit targets
audit: audit-osv audit-dep ## Run all security audits (OSV Scanner + dep_audit)

audit-osv: $(PUBSPEC) ## Run OSV Scanner security audit
	@echo "Running OSV Scanner security audit..."
	@if command -v osv-scanner >/dev/null 2>&1; then \
		osv-scanner --lockfile pubspec.lock; \
	else \
		echo "Error: osv-scanner not found. Install with: go install github.com/google/osv-scanner/cmd/osv-scanner@latest"; \
		echo "Make sure ~/go/bin is in your PATH"; \
		exit 1; \
	fi

audit-dep: $(PUBSPEC) ## Run dep_audit dependency audit
	@echo "Running dep_audit dependency audit..."
	@if command -v dep_audit >/dev/null 2>&1; then \
		dep_audit --path .; \
	else \
		echo "Error: dep_audit not found. Install with: dart pub global activate dep_audit"; \
		echo "Make sure ~/.pub-cache/bin is in your PATH"; \
		exit 1; \
	fi
