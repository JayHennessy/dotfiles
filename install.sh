#!/usr/bin/env bash
set -euo pipefail

echo "==> Jay's Dev Environment Bootstrap"
echo ""

# Install chezmoi if not present
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi..."
    sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Point chezmoi at this repo if running from a local clone,
# otherwise clone from GitHub into chezmoi's default source dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_SOURCE="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"

if [ -f "${SCRIPT_DIR}/.chezmoiroot" ] || [ -d "${SCRIPT_DIR}/dot_config" ]; then
    echo "==> Running from local clone: ${SCRIPT_DIR}"
    if [ "${SCRIPT_DIR}" != "${CHEZMOI_SOURCE}" ]; then
        rm -rf "${CHEZMOI_SOURCE}"
        ln -s "${SCRIPT_DIR}" "${CHEZMOI_SOURCE}"
        echo "==> Linked chezmoi source -> ${SCRIPT_DIR}"
    fi
    chezmoi init
else
    echo "==> Initializing dotfiles from GitHub..."
    chezmoi init JayHennessy/dotfiles
fi

# Decrypt age key before apply (needed to decrypt encrypted files)
AGE_KEY_FILE="${HOME}/.config/chezmoi/key.txt"
if [ ! -f "${AGE_KEY_FILE}" ]; then
    SOURCE_DIR="$(chezmoi source-path)"
    AGE_KEY_ENCRYPTED="${SOURCE_DIR}/key.txt.age"

    if [ -f "${AGE_KEY_ENCRYPTED}" ]; then
        # Install age if not available
        if ! command -v age &>/dev/null; then
            echo "==> Installing age..."
            TMPDIR=$(mktemp -d)
            ARCH=$(uname -m)
            case "${ARCH}" in
                x86_64)  ARCH="amd64" ;;
                aarch64) ARCH="arm64" ;;
            esac
            curl -sSfL "https://dl.filippo.io/age/latest?for=linux/${ARCH}" | tar -xz -C "${TMPDIR}"
            sudo install "${TMPDIR}/age/age" /usr/local/bin/age
            sudo install "${TMPDIR}/age/age-keygen" /usr/local/bin/age-keygen
            rm -rf "${TMPDIR}"
        fi

        echo "==> Decrypting age key (enter your passphrase)..."
        mkdir -p "$(dirname "${AGE_KEY_FILE}")"
        age --decrypt --output "${AGE_KEY_FILE}" "${AGE_KEY_ENCRYPTED}"
        chmod 600 "${AGE_KEY_FILE}"
        echo "==> age key decrypted."
    fi
fi

# Now apply with encryption key available
echo "==> Applying dotfiles..."
chezmoi apply

echo ""
echo "==> Bootstrap complete! Open a new terminal to pick up all changes."
