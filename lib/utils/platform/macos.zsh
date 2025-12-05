#!/usr/bin/env zsh
# ==============================================================================
# * ZSH MACOS PLATFORM LIBRARY
# ? macOS-specific detection, paths, and helpers.
# ? Only loaded when running on macOS systems.
# ==============================================================================

# ----------------------------------------------------------
# * PLATFORM DETECTION
# ? Must be defined early - used by guard below
# ----------------------------------------------------------

_is_macos() {
    [[ "$OSTYPE" == darwin* ]]
}

_is_bsd() {
    [[ "$OSTYPE" == freebsd* || "$OSTYPE" == openbsd* ]]
}

# ----------------------------------------------------------
# * CROSS-PLATFORM STUBS
# ? Define Linux functions that return false on macOS.
# ----------------------------------------------------------

_is_linux() { return 1 }
_is_wsl() { return 1 }

# Skip if not macOS
_is_macos || return 0

# Idempotent guard
(( ${+_ZSH_PLATFORM_MACOS_LOADED} )) && return 0
typeset -g _ZSH_PLATFORM_MACOS_LOADED=1

_log DEBUG "ZSH macOS Platform Library loading"

# ----------------------------------------------------------
# * MACOS DETECTION HELPERS
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

_is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

# ----------------------------------------------------------
# * MACOS ENVIRONMENT
# ----------------------------------------------------------

export MACOS_VERSION="${MACOS_VERSION:-$(_get_macos_version)}"
export MACOS_ARCH="${MACOS_ARCH:-$(uname -m)}"

if _is_apple_silicon; then
    export MACOS_CHIP="apple_silicon"
else
    export MACOS_CHIP="intel"
fi

export SHELL_SESSIONS_DISABLE=1
export BASH_SILENCE_DEPRECATION_WARNING=1
export BROWSER="${BROWSER:-open}"

# ----------------------------------------------------------
# * HOMEBREW DETECTION
# ? Detects Homebrew installation and sets HOMEBREW_PREFIX.
# ? Actual PATH manipulation is handled by modules/path.zsh.
# ----------------------------------------------------------

# Detect Homebrew prefix based on architecture
# ? Called by path.zsh during path_init to set up Homebrew environment
zsh_detect_homebrew() {
    # Skip if already detected
    [[ -n "$HOMEBREW_PREFIX" ]] && return 0

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

    # Set additional Homebrew environment variables if detected
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
        export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH:+:$MANPATH}"
        export INFOPATH="${HOMEBREW_PREFIX}/share/info${INFOPATH:+:$INFOPATH}"

        # GNU coreutils detection (for path.zsh to use)
        if [[ -d "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin" ]]; then
            export HOMEBREW_GNU_COREUTILS="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
        fi

        _log DEBUG "Homebrew detected at $HOMEBREW_PREFIX"
    fi
}

# Run detection immediately so HOMEBREW_PREFIX is available
zsh_detect_homebrew

# ----------------------------------------------------------
# * CLIPBOARD COMMAND
# ? Used by modules/history.zsh
# ----------------------------------------------------------

_get_clipboard_cmd() {
    echo "pbcopy"
}

# ----------------------------------------------------------
# * SSH AGENT DETECTION
# ----------------------------------------------------------

_macos_detect_ssh_agent() {
    [[ -S "${SSH_AUTH_SOCK:-}" ]] && return 0

    # 1Password SSH Agent
    local op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    [[ -S "$op_sock" ]] && { export SSH_AUTH_SOCK="$op_sock"; return 0; }

    # GPG Agent
    local gpg_sock="$HOME/.gnupg/S.gpg-agent.ssh"
    [[ -S "$gpg_sock" ]] && { export SSH_AUTH_SOCK="$gpg_sock"; return 0; }

    return 0
}

# ----------------------------------------------------------
# * UTILITY FUNCTIONS
# ? Used via aliases in modules/aliases.zsh
# ----------------------------------------------------------

# Kill an application by name
zsh_killapp() {
    local app="${1:?Usage: killapp <app_name>}"
    osascript -e "tell application \"$app\" to quit" 2>/dev/null || \
        pkill -x "$app" 2>/dev/null || \
        echo "Could not quit $app" >&2
}

# Get current Wi-Fi network name
zsh_wifi_name() {
    networksetup -getairportnetwork en0 2>/dev/null | awk -F': ' '{print $2}'
}

# Show Wi-Fi password for current or specified network
zsh_wifi_password() {
    local network="${1:-$(zsh_wifi_name)}"
    [[ -z "$network" ]] && { echo "Not connected to Wi-Fi" >&2; return 1; }
    security find-generic-password -ga "$network" 2>&1 | grep "password:" | cut -d'"' -f2
}

# Check recommended tools
zsh_macos_check_tools() {
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

    (( ${#missing[@]} )) && echo "\nInstall: brew install ${missing[*]}"
}

# ----------------------------------------------------------
_log DEBUG "ZSH macOS Platform Library loaded"
