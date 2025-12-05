#!/usr/bin/env zsh
# ==============================================================================
# * ZSH LINUX PLATFORM LIBRARY
# ? Linux-specific detection, paths, and helpers.
# ? Only loaded when running on Linux systems.
# ==============================================================================

# ----------------------------------------------------------
# * PLATFORM DETECTION
# ? Must be defined early - used by guard below
# ----------------------------------------------------------

_is_linux() {
    [[ "$OSTYPE" == linux* ]]
}

_is_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null
}

# ----------------------------------------------------------
# * CROSS-PLATFORM STUBS
# ? Define macOS functions that return false on Linux.
# ----------------------------------------------------------

_is_macos() { return 1 }
_is_bsd() { return 1 }
_is_apple_silicon() { return 1 }

# Skip if not Linux
_is_linux || return 0

# Idempotent guard
(( ${+_ZSH_PLATFORM_LINUX_LOADED} )) && return 0
typeset -g _ZSH_PLATFORM_LINUX_LOADED=1

_log DEBUG "ZSH Linux Platform Library loading"

# ----------------------------------------------------------
# * LINUX DETECTION HELPERS
# ----------------------------------------------------------

_get_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${ID:-unknown}"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/alpine-release ]]; then
        echo "alpine"
    else
        echo "unknown"
    fi
}

_get_linux_family() {
    local distro
    distro=$(_get_linux_distro)

    case "$distro" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali) echo "debian" ;;
        fedora|centos|rhel|rocky|alma|oracle) echo "rhel" ;;
        arch|manjaro|endeavouros|garuda) echo "arch" ;;
        opensuse*|suse*) echo "suse" ;;
        alpine) echo "alpine" ;;
        nixos) echo "nix" ;;
        *) echo "unknown" ;;
    esac
}

# ----------------------------------------------------------
# * LINUX ENVIRONMENT
# ----------------------------------------------------------

export LINUX_DISTRO="${LINUX_DISTRO:-$(_get_linux_distro)}"
export LINUX_FAMILY="${LINUX_FAMILY:-$(_get_linux_family)}"

# Detect display server
if [[ -n "$WAYLAND_DISPLAY" ]]; then
    export DISPLAY_SERVER="wayland"
elif [[ -n "$DISPLAY" ]]; then
    export DISPLAY_SERVER="x11"
else
    export DISPLAY_SERVER="none"
fi

# XDG runtime directory
if [[ -z "$XDG_RUNTIME_DIR" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$UID"
    if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
        export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
        mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null
        chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null
    fi
fi

# D-Bus session bus
if [[ -z "$DBUS_SESSION_BUS_ADDRESS" && -S "$XDG_RUNTIME_DIR/bus" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi

# ----------------------------------------------------------
# * LINUX-SPECIFIC PATHS
# ----------------------------------------------------------

# Snap packages
[[ -d /snap/bin ]] && path=(/snap/bin $path)

# Flatpak
[[ -d /var/lib/flatpak/exports/bin ]] && path=(/var/lib/flatpak/exports/bin $path)
[[ -d "$HOME/.local/share/flatpak/exports/bin" ]] && path=("$HOME/.local/share/flatpak/exports/bin" $path)

# AppImage / local bin
[[ -d "$HOME/Applications" ]] && path=("$HOME/Applications" $path)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)

# Linuxbrew
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
elif [[ -d "$HOME/.linuxbrew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv 2>/dev/null)"
fi

# Nix
[[ -d /nix/var/nix/profiles/default/bin ]] && path=(/nix/var/nix/profiles/default/bin $path)
[[ -d "$HOME/.nix-profile/bin" ]] && path=("$HOME/.nix-profile/bin" $path)

# ccache
[[ -d /usr/lib/ccache ]] && path=(/usr/lib/ccache $path)

# Games
[[ -d /usr/games ]] && path=($path /usr/games)

# ----------------------------------------------------------
# * PACKAGE MANAGER DETECTION
# ----------------------------------------------------------

_get_package_manager() {
    case "$LINUX_FAMILY" in
        debian) _has_cmd apt && echo "apt" || echo "apt-get" ;;
        rhel)
            if _has_cmd dnf; then echo "dnf"
            elif _has_cmd yum; then echo "yum"
            else echo "none"; fi ;;
        arch) _has_cmd pacman && echo "pacman" || echo "none" ;;
        alpine) _has_cmd apk && echo "apk" || echo "none" ;;
        suse) _has_cmd zypper && echo "zypper" || echo "none" ;;
        nix) _has_cmd nix-env && echo "nix" || echo "none" ;;
        *)
            if _has_cmd apt; then echo "apt"
            elif _has_cmd dnf; then echo "dnf"
            elif _has_cmd pacman; then echo "pacman"
            elif _has_cmd apk; then echo "apk"
            elif _has_cmd zypper; then echo "zypper"
            elif _has_cmd brew; then echo "brew"
            else echo "none"; fi ;;
    esac
}

_get_install_cmd() {
    local tool="$1"
    case "$(_get_package_manager)" in
        apt|apt-get) echo "sudo apt install $tool" ;;
        dnf) echo "sudo dnf install $tool" ;;
        yum) echo "sudo yum install $tool" ;;
        pacman) echo "sudo pacman -S $tool" ;;
        apk) echo "sudo apk add $tool" ;;
        zypper) echo "sudo zypper install $tool" ;;
        brew) echo "brew install $tool" ;;
        *) echo "# Install $tool using your package manager" ;;
    esac
}

# ----------------------------------------------------------
# * CLIPBOARD COMMAND
# ? Used by modules/history.zsh
# ----------------------------------------------------------

_get_clipboard_cmd() {
    if [[ -n "$WAYLAND_DISPLAY" ]] && _has_cmd wl-copy; then
        echo "wl-copy"
    elif _has_cmd xclip; then
        echo "xclip -selection clipboard"
    elif _has_cmd xsel; then
        echo "xsel --clipboard --input"
    elif _is_wsl; then
        echo "clip.exe"
    else
        echo "cat > /dev/null"
    fi
}

# ----------------------------------------------------------
# * SSH AGENT DETECTION
# ----------------------------------------------------------

_linux_detect_ssh_agent() {
    [[ -S "${SSH_AUTH_SOCK:-}" ]] && return 0

    # GNOME Keyring
    local gnome_sock="$XDG_RUNTIME_DIR/keyring/ssh"
    [[ -S "$gnome_sock" ]] && { export SSH_AUTH_SOCK="$gnome_sock"; return 0; }

    # GPG Agent
    local gpg_sock="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
    [[ -S "$gpg_sock" ]] && { export SSH_AUTH_SOCK="$gpg_sock"; return 0; }

    # KDE Wallet / systemd
    local kde_sock="$XDG_RUNTIME_DIR/ssh-agent.socket"
    [[ -S "$kde_sock" ]] && { export SSH_AUTH_SOCK="$kde_sock"; return 0; }

    return 1
}

# ----------------------------------------------------------
# * UTILITY FUNCTIONS
# ? Used via aliases in modules/aliases.zsh
# ----------------------------------------------------------

zsh_linux_check_tools() {
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

    (( ${#missing[@]} )) && echo "\nInstall: $(_get_install_cmd "${missing[*]}")"
}

# ----------------------------------------------------------
# * WSL-SPECIFIC CONFIGURATION
# ----------------------------------------------------------

if _is_wsl; then
    _log DEBUG "WSL environment detected"
    export BROWSER="wslview"
    export WINHOME="/mnt/c/Users/${USER}"

    if [[ -z "$WSL_INTEROP" && -e /run/WSL/* ]]; then
        export WSL_INTEROP="$(ls /run/WSL/* 2>/dev/null | head -1)"
    fi
fi

# ----------------------------------------------------------
_log DEBUG "ZSH Linux Platform Library loaded"
