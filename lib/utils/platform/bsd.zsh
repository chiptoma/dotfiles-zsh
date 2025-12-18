#!/usr/bin/env zsh
# ==============================================================================
# ZSH BSD PLATFORM LIBRARY
# FreeBSD/OpenBSD/NetBSD-specific environment, paths, and helpers.
# Only loaded when running on BSD (detect.zsh handles detection).
# ==============================================================================

# Idempotent guard
(( ${+_Z_PLATFORM_BSD_LOADED} )) && return 0
typeset -g _Z_PLATFORM_BSD_LOADED=1

_log DEBUG "ZSH BSD Platform Library loading"

# ----------------------------------------------------------
# BSD VERSION DETECTION
# Provides BSD variant and version info
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
# BSD ENVIRONMENT
# Exported for user scripts and diagnostics (zsh_status)
# ----------------------------------------------------------

export BSD_VARIANT="${BSD_VARIANT:-$(_get_bsd_variant)}"
export BSD_VERSION="${BSD_VERSION:-$(_get_bsd_version)}"
export BSD_ARCH="${BSD_ARCH:-$_CACHED_UNAME_M}"

# ----------------------------------------------------------
# PACKAGE MANAGER DETECTION
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

# Cache pkg manager at load time (used by _get_install_cmd)
typeset -g _CACHED_BSD_PKG_MANAGER="${_CACHED_BSD_PKG_MANAGER:-$(_bsd_detect_pkg_manager)}"

# ----------------------------------------------------------
# CLIPBOARD COMMAND
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
# PACKAGE MANAGER
# ----------------------------------------------------------

_get_install_cmd() {
    local tools="$1"
    case "$_CACHED_BSD_PKG_MANAGER" in
        pkg)     echo "pkg install $tools" ;;
        pkg_add) echo "pkg_add $tools" ;;
        pkgin)   echo "pkgin install $tools" ;;
        *)       echo "# Install $tools using your package manager" ;;
    esac
}

# ----------------------------------------------------------
_log DEBUG "ZSH BSD Platform Library loaded"
