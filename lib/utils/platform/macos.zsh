#!/usr/bin/env zsh
# ==============================================================================
# ZSH MACOS PLATFORM LIBRARY
# macOS-specific environment, paths, and helpers.
# Only loaded when running on macOS (detect.zsh handles detection).
# ==============================================================================

# Idempotent guard
(( ${+_Z_PLATFORM_MACOS_LOADED} )) && return 0
typeset -g _Z_PLATFORM_MACOS_LOADED=1

_log DEBUG "ZSH macOS Platform Library loading"

# ----------------------------------------------------------
# MACOS VERSION DETECTION
# Provides human-readable macOS version name
# ----------------------------------------------------------

_get_macos_version() {
    local version
    version=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)

    case "$version" in
        15) echo "sequoia" ;;
        14) echo "sonoma" ;;
        13) echo "ventura" ;;
        12) echo "monterey" ;;
        11) echo "big_sur" ;;
        10) echo "catalina_or_older" ;;
        *)  echo "unknown" ;;
    esac
}

# ----------------------------------------------------------
# MACOS ENVIRONMENT
# Exported for user scripts and diagnostics (zsh_status)
# ----------------------------------------------------------

export MACOS_VERSION="${MACOS_VERSION:-$(_get_macos_version)}"
export MACOS_ARCH="${MACOS_ARCH:-$_CACHED_UNAME_M}"
if _is_apple_silicon; then
    export MACOS_CHIP="apple_silicon"
else
    export MACOS_CHIP="intel"
fi

export SHELL_SESSIONS_DISABLE=1
export BASH_SILENCE_DEPRECATION_WARNING=1
export BROWSER="${BROWSER:-open}"

# ----------------------------------------------------------
# HOMEBREW DETECTION
# Detects Homebrew installation and sets HOMEBREW_PREFIX.
# Actual PATH manipulation is handled by modules/path.zsh.
# ----------------------------------------------------------

_detect_homebrew() {
    # Skip if already detected AND valid
    if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX" ]]; then
        return 0
    fi

    # Clear any invalid/corrupted value
    unset HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY

    if _is_apple_silicon; then
        if [[ -x /opt/homebrew/bin/brew ]]; then
            export HOMEBREW_PREFIX="/opt/homebrew"
            export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
            export HOMEBREW_REPOSITORY="/opt/homebrew"
        fi
    else
        if [[ -x /usr/local/bin/brew ]]; then
            export HOMEBREW_PREFIX="/usr/local"
            export HOMEBREW_CELLAR="/usr/local/Cellar"
            export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
        fi
    fi

    if [[ -n "$HOMEBREW_PREFIX" ]]; then
        export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH:+:$MANPATH}"
        export INFOPATH="${HOMEBREW_PREFIX}/share/info${INFOPATH:+:$INFOPATH}"

        if [[ -d "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin" ]]; then
            export HOMEBREW_GNU_COREUTILS="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
        fi

        _log DEBUG "Homebrew detected at $HOMEBREW_PREFIX"
    fi
}

# Run detection immediately
_detect_homebrew

# ----------------------------------------------------------
# CLIPBOARD COMMAND
# ----------------------------------------------------------

_get_clipboard_cmd() {
    echo "pbcopy"
}

# ----------------------------------------------------------
# PACKAGE MANAGER
# ----------------------------------------------------------

_get_install_cmd() {
    local tools="$1"
    echo "brew install $tools"
}

# ----------------------------------------------------------
_log DEBUG "ZSH macOS Platform Library loaded"
