.PHONY: build em_deploy em_run em_launch install clean help

.DEFAULT_GOAL := help

# Configuration
EMULATOR_NAME := goldfish_emulator
APK_PATH := build/app/outputs/flutter-apk/app-release.apk
PACKAGE_NAME := dev.goldfish.app
MAIN_ACTIVITY := $(PACKAGE_NAME)/.MainActivity

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build release APK
	@echo "Building release APK..."
	flutter build apk --release
	@echo "APK built at: $(APK_PATH)"

em_launch: ## Launch the emulator
	@echo "Launching emulator: $(EMULATOR_NAME)"
	flutter emulators --launch $(EMULATOR_NAME)

install: build ## Install APK on connected device/emulator
	@echo "Installing APK..."
	@if adb devices | grep -q "device$$"; then \
		adb install -r $(APK_PATH); \
		echo "APK installed successfully"; \
	else \
		echo "Error: No device/emulator connected. Run 'make em_launch' first."; \
		exit 1; \
	fi

em_deploy: build ## Build and deploy APK to emulator
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

em_run: ## Run app on emulator (builds and installs automatically)
	@echo "Running app on emulator..."
	flutter run

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	flutter clean
	@echo "Clean complete"

