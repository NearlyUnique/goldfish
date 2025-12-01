#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

HELP_README="README.md (Tooling Setup section)"
HELP_BOOTSTRAP="prompts/01_bootstrap_project.md (Verification Checklist)"

FAILED=0
PROJECT_INITIALIZED=0

heading() {
  printf '\n== %s ==\n' "$1"
}

pass() {
  printf '[OK] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  FAILED=1
}

note() {
  printf '[NOTE] %s\n' "$1"
}

ensure_repo_root() {
  heading "Project root"
  if [[ -f pubspec.yaml ]]; then
    pass "Found pubspec.yaml; running from repository root."
    PROJECT_INITIALIZED=1
    return
  fi

  if [[ -f README.md && -d prompts ]]; then
    note "Flutter project not initialized yet (pubspec.yaml missing)."
    note "Run 'flutter create .' per $HELP_BOOTSTRAP to generate project files."
    PROJECT_INITIALIZED=0
  else
    fail "pubspec.yaml not found. Run this script from the project root."
    printf 'Refer to %s for project layout details.\n' "$HELP_BOOTSTRAP"
    exit 1
  fi
}

check_command() {
  local cmd="$1"
  local help_ref="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local location
    location="$(command -v "$cmd")"
    pass "$cmd available at $location."
  else
    fail "$cmd is missing. See $help_ref for setup instructions."
  fi
}

check_env_path() {
  local var_name="$1"
  local help_ref="$2"
  local value="${!var_name:-}"

  if [[ -z "$value" ]]; then
    fail "$var_name is not set. See $help_ref for guidance."
    return
  fi

  if [[ -d "$value" ]]; then
    pass "$var_name points to $value."
  else
    fail "$var_name points to '$value', but the directory is missing. See $help_ref."
  fi
}

run_flutter_doctor() {
  heading "flutter doctor"
  if command -v flutter >/dev/null 2>&1; then
    if flutter doctor -v; then
      pass "flutter doctor completed."
    else
      fail "flutter doctor reported issues. Review the output above and consult $HELP_README."
    fi
  else
    fail "Skipping flutter doctor because flutter is not installed."
  fi
}

check_adb_devices() {
  heading "adb devices"
  if command -v adb >/dev/null 2>&1; then
    if adb devices; then
      pass "ADB responded. Ensure at least one device/emulator is listed when connected."
    else
      fail "adb devices failed. See $HELP_README for Android device setup."
    fi
  else
    fail "adb not found. See $HELP_README for Android SDK instructions."
  fi
}

check_optional_command() {
  local cmd="$1"
  local help_ref="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local location
    location="$(command -v "$cmd")"
    pass "$cmd available at $location."
  else
    note "$cmd is not installed (optional). See $help_ref for setup instructions."
  fi
}

check_security_audit_tools() {
  heading "Security audit tools (optional)"
  check_optional_command "osv-scanner" "$HELP_README -> Security Auditing"
  check_optional_command "dep_audit" "$HELP_README -> Security Auditing"

  # Check if PATH includes the directories where these tools are typically installed
  if [[ ":$PATH:" != *":$HOME/go/bin:"* ]] && [[ ":$PATH:" != *":$HOME/.pub-cache/bin:"* ]]; then
    note "Consider adding ~/go/bin and ~/.pub-cache/bin to PATH for security audit tools."
    note "Run: bash scripts/check_audit_tools.sh for detailed setup instructions."
  fi
}

check_coverage_tools() {
  heading "Code coverage tools (optional)"
  check_optional_command "genhtml" "$HELP_README -> Testing -> Code Coverage"
}

ensure_repo_root

heading "CLI availability"
check_command "flutter" "$HELP_README -> Flutter SDK"
check_command "dart" "$HELP_README -> Flutter SDK (Dart is included with Flutter)"
check_command "adb" "$HELP_README -> Android Development Tools"
check_command "git" "$HELP_README -> Tooling Setup -> Git"
check_command "java" "$HELP_README -> Android Development Tools (JDK)"

heading "Environment variables"
check_env_path "ANDROID_HOME" "$HELP_README -> Android Development Tools"

run_flutter_doctor
check_adb_devices
check_security_audit_tools
check_coverage_tools

heading "Next steps"
printf 'For build, test, and APK verification guidance see %s.\n' "$HELP_BOOTSTRAP"
printf 'For detailed tooling and troubleshooting help see %s.\n' "$HELP_README"
if (( PROJECT_INITIALIZED == 0 )); then
  note "Initialize the Flutter project with 'flutter create .' once tooling is ready."
fi

if (( FAILED == 0 )); then
  heading "Result"
  pass "Environment looks ready to start development."
  exit 0
else
  heading "Result"
  fail "One or more checks failed. Resolve issues using the references above."
  exit 1
fi

