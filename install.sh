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

# Init dotfiles (generates config, does NOT apply yet)
echo "==> Initializing dotfiles with chezmoi..."
chezmoi init JayHennessy/dotfiles

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
