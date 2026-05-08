#!/usr/bin/env bash
set -euo pipefail

if command -v docker &>/dev/null; then
    echo "==> Docker already installed, skipping."
    exit 0
fi

if ! command -v sudo &>/dev/null || ! sudo -n true 2>/dev/null; then
    echo "==> No sudo access — skipping Docker install."
    exit 0
fi

echo "==> Installing Docker..."
curl -fsSL https://get.docker.com | sh

# Add current user to docker group
sudo usermod -aG docker "$USER"

echo "==> Docker installed: $(docker --version)"
echo "    NOTE: Log out and back in for docker group membership to take effect."
