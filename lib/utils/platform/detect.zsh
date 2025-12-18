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
# BSD VARIANTS
# Detects FreeBSD, OpenBSD, and NetBSD systems
# ----------------------------------------------------------

_is_freebsd() {
    [[ "$OSTYPE" == freebsd* ]]
}

_is_openbsd() {
    [[ "$OSTYPE" == openbsd* ]]
}

_is_netbsd() {
    [[ "$OSTYPE" == netbsd* ]]
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
    local -a tools=(
        "fzf:Fuzzy finder"
        "ripgrep:Fast grep (rg)"
        "fd:Modern find"
        "bat:Better cat"
        "eza:Modern ls"
        "zoxide:Smart cd"
        "starship:Prompt"
    )

    echo "Checking tools..."
    for entry in "${tools[@]}"; do
        local cmd="${entry%%:*}" desc="${entry#*:}"
        [[ "$cmd" == "ripgrep" ]] && cmd="rg"
        if _has_cmd "$cmd"; then
            echo "  ✓ ${entry%%:*} - $desc"
        else
            echo "  ✗ ${entry%%:*} - $desc"
            missing+=("${entry%%:*}")
        fi
    done

    if (( ${#missing[@]} )); then
        echo ""
        echo "Install: $(_get_install_cmd "${missing[*]}")"
    fi
}
