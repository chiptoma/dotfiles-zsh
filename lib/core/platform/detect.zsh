#!/usr/bin/env zsh
# ==============================================================================
# ZSH PLATFORM DETECTION
# Unified platform detection functions. Loaded once, used everywhere.
# ==============================================================================

# Idempotent guard
(( ${+_Z_PLATFORM_DETECT_LOADED} )) && return 0
typeset -g _Z_PLATFORM_DETECT_LOADED=1

# ----------------------------------------------------------
# PRIMARY PLATFORM DETECTION
# ----------------------------------------------------------

_is_macos() {
    [[ "$OSTYPE" == darwin* ]]
}

_is_linux() {
    [[ "$OSTYPE" == linux* ]]
}

_is_bsd() {
    [[ "$OSTYPE" == freebsd* || "$OSTYPE" == openbsd* || "$OSTYPE" == netbsd* ]]
}

# ----------------------------------------------------------
# LINUX VARIANTS
# Detects specific Linux distributions and environments (WSL, etc.)
# ----------------------------------------------------------

# Cache WSL detection at load time (avoids grep on every call)
typeset -g _CACHED_IS_WSL=""
if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    _CACHED_IS_WSL=1
fi

_is_wsl() {
    [[ -n "$_CACHED_IS_WSL" ]]
}

# ----------------------------------------------------------
# ARCHITECTURE DETECTION
# Detects CPU architecture (ARM, x86_64, Apple Silicon)
# ----------------------------------------------------------

# Cache uname -m to avoid repeated subprocess calls
typeset -g _CACHED_UNAME_M="${_CACHED_UNAME_M:-$(uname -m)}"

_is_apple_silicon() {
    [[ "$OSTYPE" == darwin* && "$_CACHED_UNAME_M" == "arm64" ]]
}

_is_arm() {
    [[ "$_CACHED_UNAME_M" == arm* || "$_CACHED_UNAME_M" == aarch64 ]]
}

_is_x86_64() {
    [[ "$_CACHED_UNAME_M" == x86_64 || "$_CACHED_UNAME_M" == amd64 ]]
}

# ----------------------------------------------------------
# SSH AGENT DETECTION
# Detects and configures SSH agent socket from various providers.
# Priority: 1Password (macOS) > 1Password (~/.1password) > GPG Agent
#   > GNOME Keyring > System default
# NOTE: Boot-time check is socket EXISTENCE only — no liveness probe
#   (a connect can hang and would tax every shell start). Liveness is
#   checked on demand by z_ssh_agent / z_health.
# ----------------------------------------------------------

_detect_ssh_agent() {
    # 1Password SSH Agent — macOS app-container path, then the
    # cross-platform ~/.1password symlink (native path on Linux)
    local op_sock_mac="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    local op_sock="$HOME/.1password/agent.sock"

    # GPG Agent SSH socket
    local gpg_sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/gnupg/S.gpg-agent.ssh"

    # GNOME Keyring SSH socket
    local gnome_sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/keyring/ssh"

    # Check dedicated agent sockets first — macOS always pre-populates
    # SSH_AUTH_SOCK with its own launchd socket, which would otherwise
    # short-circuit this before 1Password/GPG/GNOME get a chance.
    if [[ -S "$op_sock_mac" ]]; then
        export SSH_AUTH_SOCK="$op_sock_mac"
    elif [[ -S "$op_sock" ]]; then
        export SSH_AUTH_SOCK="$op_sock"
    elif [[ -S "$gpg_sock" ]]; then
        export SSH_AUTH_SOCK="$gpg_sock"
    elif [[ -S "$gnome_sock" ]]; then
        export SSH_AUTH_SOCK="$gnome_sock"
    elif [[ -S "${SSH_AUTH_SOCK:-}" ]]; then
        # Already set to some other valid socket — leave it alone.
        return 0
    fi

    return 0
}

# ----------------------------------------------------------
# FALLBACK IMPLEMENTATIONS
# Used when no platform-specific file is loaded.
# Platform files (macos.zsh, linux.zsh, bsd.zsh) override these.
# ----------------------------------------------------------

# Clipboard command fallback (no-op)
(( $+functions[_get_clipboard_cmd] )) || _get_clipboard_cmd() {
    echo "cat > /dev/null"  # Fallback: discard
}

# Install command fallback (generic hint)
(( $+functions[_get_install_cmd] )) || _get_install_cmd() {
    local tools="$1"
    echo "# Install: $tools (use your system's package manager)"
}

# ----------------------------------------------------------
# TOOL CHECKING
# Shared function - uses platform-specific _get_install_cmd
# ----------------------------------------------------------

_check_tools() {
    local -a missing=()

    # Catalog-driven (lib/registry/tools.dat); extras are opt-in, skip them
    if ! (( $+functions[_z_tools_load] )) || ! _z_tools_load; then
        echo "Tool catalog unavailable (lib/registry not loaded)"
        return 1
    fi

    echo "Checking tools..."
    local name binary desc category
    for name in "${Z_TOOL_NAMES[@]}"; do
        local -a fields=("${(@s.:.)Z_TOOLS[$name]}")
        binary="${fields[1]}" desc="${fields[2]}" category="${fields[3]}"
        [[ "$category" == "extra" ]] && continue
        if _has_cmd "$binary"; then
            echo "  ✓ $name - $desc"
        else
            echo "  ✗ $name - $desc"
            missing+=("$name")
        fi
    done

    if (( ${#missing[@]} )); then
        echo ""
        echo "Install: $(_get_install_cmd "${missing[*]}")"
    fi
}
