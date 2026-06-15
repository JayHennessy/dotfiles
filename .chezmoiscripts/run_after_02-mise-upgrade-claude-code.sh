#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v mise &>/dev/null; then
    echo "==> mise not found, skipping claude-code upgrade."
    exit 0
fi

# Provide a GitHub token so resolving the latest version doesn't hit the
# unauthenticated API rate limit. (mise isn't activated here, so `gh` is the
# system gh, not mise's.)
if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh &>/dev/null; then
    GITHUB_TOKEN="$(gh auth token 2>/dev/null || true)"
    [ -n "${GITHUB_TOKEN}" ] && export GITHUB_TOKEN
fi

tool="aqua:anthropics/claude-code"

# Refresh the cache so `mise latest` reflects the true newest release.
mise cache clean >/dev/null 2>&1 || true

latest_version="$(mise latest "${tool}" 2>/dev/null || echo unknown)"
installed_version="$(mise current "${tool}" 2>/dev/null || echo none)"

if [ "${latest_version}" != "unknown" ] && [ "${installed_version}" = "${latest_version}" ]; then
    echo "==> claude-code already at latest (${installed_version}), skipping."
    exit 0
fi

echo "==> Upgrading claude-code: ${installed_version} -> ${latest_version}..."
mise install -y "${tool}@latest"
echo "==> claude-code now at: $(mise current "${tool}" 2>/dev/null || echo unknown)"
