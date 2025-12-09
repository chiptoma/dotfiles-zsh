#!/usr/bin/env zsh
# ==============================================================================
# * ZSH BSD PLATFORM LIBRARY
# ? FreeBSD/OpenBSD/NetBSD-specific detection, paths, and helpers.
# ? Only loaded when running on BSD systems.
# ==============================================================================

# ----------------------------------------------------------
# * PLATFORM DETECTION
# ? Must be defined early - used by guard below
# ----------------------------------------------------------

_is_bsd() {
    [[ "$OSTYPE" == freebsd* || "$OSTYPE" == openbsd* || "$OSTYPE" == netbsd* ]]
}

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
# * CROSS-PLATFORM STUBS
# ? Define other platform functions that return false on BSD.
# ----------------------------------------------------------

_is_macos() { return 1 }
_is_linux() { return 1 }
_is_wsl() { return 1 }
_is_apple_silicon() { return 1 }

# Skip if not BSD
_is_bsd || return 0

# Idempotent guard
(( ${+_ZSH_PLATFORM_BSD_LOADED} )) && return 0
typeset -g _ZSH_PLATFORM_BSD_LOADED=1

_log DEBUG "ZSH BSD Platform Library loading"

# ----------------------------------------------------------
# * BSD DETECTION HELPERS
# ----------------------------------------------------------

_get_bsd_variant() {
    case "$OSTYPE" in
        freebsd*) echo "freebsd" ;;
        openbsd*) echo "openbsd" ;;
        netbsd*)  echo "netbsd" ;;
        *)        echo "unknown" ;;
    esac
}

_get_bsd_version() {
    uname -r 2>/dev/null | cut -d'-' -f1
}

# ----------------------------------------------------------
# * BSD ENVIRONMENT
# ----------------------------------------------------------

export BSD_VARIANT="${BSD_VARIANT:-$(_get_bsd_variant)}"
export BSD_VERSION="${BSD_VERSION:-$(_get_bsd_version)}"

# ? Cache uname -m result to avoid multiple subprocess calls
typeset -g _BSD_UNAME_M="${_BSD_UNAME_M:-$(uname -m)}"
export BSD_ARCH="${BSD_ARCH:-$_BSD_UNAME_M}"

# ----------------------------------------------------------
# * PACKAGE MANAGER DETECTION
# ----------------------------------------------------------

_bsd_detect_pkg_manager() {
    if _has_cmd pkg; then
        echo "pkg"          # FreeBSD
    elif _has_cmd pkg_add; then
        echo "pkg_add"      # OpenBSD
    elif _has_cmd pkgin; then
        echo "pkgin"        # NetBSD pkgsrc
    else
        echo ""
    fi
}

export BSD_PKG_MANAGER="${BSD_PKG_MANAGER:-$(_bsd_detect_pkg_manager)}"

# ----------------------------------------------------------
# * CLIPBOARD COMMAND
# ? Used by modules/history.zsh and lib/functions/introspection.zsh
# ----------------------------------------------------------

_get_clipboard_cmd() {
    if [[ -n "$DISPLAY" ]] && _has_cmd xclip; then
        echo "xclip -selection clipboard"
    elif [[ -n "$DISPLAY" ]] && _has_cmd xsel; then
        echo "xsel --clipboard --input"
    else
        echo "cat"  # Fallback: no clipboard
    fi
}

# ----------------------------------------------------------
# * BSD-SPECIFIC HELPERS
# ----------------------------------------------------------

# Check recommended tools for BSD
zsh_bsd_check_tools() {
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
        case "$BSD_PKG_MANAGER" in
            pkg)     echo "Install: pkg install ${missing[*]}" ;;
            pkg_add) echo "Install: pkg_add ${missing[*]}" ;;
            pkgin)   echo "Install: pkgin install ${missing[*]}" ;;
            *)       echo "Install missing tools using your package manager" ;;
        esac
    fi
}

# ----------------------------------------------------------
_log DEBUG "ZSH BSD Platform Library loaded"
