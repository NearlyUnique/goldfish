#!/bin/bash
# Check if security audit tools are installed and available

set -e

echo "Checking security audit tools..."

# Check OSV Scanner
if command -v osv-scanner >/dev/null 2>&1; then
    echo "✅ osv-scanner is installed: $(osv-scanner --version | head -1)"
else
    echo "❌ osv-scanner not found"
    echo "   Install with: go install github.com/google/osv-scanner/cmd/osv-scanner@latest"
    echo "   Make sure ~/go/bin is in your PATH"
    echo "   Add to ~/.zshrc or ~/.bashrc: export PATH=\"\$PATH:\$HOME/go/bin\""
fi

# Check dep_audit
if command -v dep_audit >/dev/null 2>&1; then
    echo "✅ dep_audit is installed"
else
    echo "❌ dep_audit not found"
    echo "   Install with: dart pub global activate dep_audit"
    echo "   Make sure ~/.pub-cache/bin is in your PATH"
    echo "   Add to ~/.zshrc or ~/.bashrc: export PATH=\"\$PATH:\$HOME/.pub-cache/bin\""
fi

# Check PATH
if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    echo "⚠️  ~/go/bin is not in PATH"
fi

if [[ ":$PATH:" != *":$HOME/.pub-cache/bin:"* ]]; then
    echo "⚠️  ~/.pub-cache/bin is not in PATH"
fi

echo ""
echo "To add both to your PATH, run:"
echo "  echo 'export PATH=\"\$PATH:\$HOME/go/bin:\$HOME/.pub-cache/bin\"' >> ~/.zshrc"
echo "  source ~/.zshrc"

