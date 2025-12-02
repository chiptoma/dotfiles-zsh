#!/bin/bash
# ==============================================================================
# * DEVCONTAINER SETUP
# ? Initializes the ZSH configuration in a devcontainer environment.
# ==============================================================================

set -e

echo "=== Setting up ZSH Configuration ==="

# Install the configuration using the installer
./install.sh --yes

# Install recommended tools
echo ""
echo "=== Installing recommended tools ==="

# Install starship prompt
if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# Install eza (modern ls)
if ! command -v eza &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y eza 2>/dev/null || true
fi

# Install bat (modern cat)
if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
    sudo apt-get install -y bat 2>/dev/null || true
fi

# Install ripgrep
if ! command -v rg &>/dev/null; then
    sudo apt-get install -y ripgrep 2>/dev/null || true
fi

# Install fzf
if ! command -v fzf &>/dev/null; then
    sudo apt-get install -y fzf 2>/dev/null || true
fi

echo ""
echo "=== Setup complete ==="
echo "Restart your terminal or run 'exec zsh' to use the new configuration."
