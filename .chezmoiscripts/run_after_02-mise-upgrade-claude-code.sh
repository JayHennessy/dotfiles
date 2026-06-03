#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v mise &>/dev/null; then
    echo "==> mise not found, skipping claude-code upgrade."
    exit 0
fi

echo "==> Refreshing mise cache and upgrading claude-code to latest..."
mise cache clean >/dev/null 2>&1 || true
mise install -y --force aqua:anthropics/claude-code@latest

installed_version="$(mise current aqua:anthropics/claude-code 2>/dev/null || echo unknown)"
echo "==> claude-code now at: ${installed_version}"
