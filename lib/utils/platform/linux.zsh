#!/usr/bin/env zsh
# ==============================================================================
# ZSH LINUX PLATFORM LIBRARY
# Linux-specific environment, paths, and helpers.
# Only loaded when running on Linux (detect.zsh handles detection).
# ==============================================================================

# Idempotent guard
(( ${+_Z_PLATFORM_LINUX_LOADED} )) && return 0
typeset -g _Z_PLATFORM_LINUX_LOADED=1

_log DEBUG "ZSH Linux Platform Library loading"

# ----------------------------------------------------------
# LINUX DISTRO DETECTION
# ----------------------------------------------------------

_get_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        local id_line
        id_line=$(grep -E '^ID=' /etc/os-release 2>/dev/null | head -1)
        local id="${id_line#ID=}"
        id="${id//\"/}"
        echo "${id:-unknown}"
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
    # Use cached distro if available
    local distro="${_CACHED_LINUX_DISTRO:-$(_get_linux_distro)}"

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
# LINUX ENVIRONMENT
# Internal caches used by _get_package_manager()
# ----------------------------------------------------------

typeset -g _CACHED_LINUX_DISTRO="${_CACHED_LINUX_DISTRO:-$(_get_linux_distro)}"
typeset -g _CACHED_LINUX_FAMILY="${_CACHED_LINUX_FAMILY:-$(_get_linux_family)}"

# ----------------------------------------------------------
# LINUX EXPORTS
# Exported for user scripts and diagnostics (zsh_status)
# ----------------------------------------------------------

export LINUX_DISTRO="$_CACHED_LINUX_DISTRO"
export LINUX_FAMILY="$_CACHED_LINUX_FAMILY"
export LINUX_ARCH="${LINUX_ARCH:-$_CACHED_UNAME_M}"

# Detect display server (Wayland/X11/none)
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
# LINUX-SPECIFIC PATHS
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
# PACKAGE MANAGER DETECTION
# ----------------------------------------------------------

# Cache for package manager (set on first call)
typeset -g _CACHED_LINUX_PKG_MANAGER=""

_get_package_manager() {
    # Return cached value if available
    if [[ -n "$_CACHED_LINUX_PKG_MANAGER" ]]; then
        echo "$_CACHED_LINUX_PKG_MANAGER"
        return 0
    fi

    local pm=""
    case "$_CACHED_LINUX_FAMILY" in
        debian) _has_cmd apt && pm="apt" || pm="apt-get" ;;
        rhel)
            if _has_cmd dnf; then pm="dnf"
            elif _has_cmd yum; then pm="yum"
            else pm="none"; fi ;;
        arch) _has_cmd pacman && pm="pacman" || pm="none" ;;
        alpine) _has_cmd apk && pm="apk" || pm="none" ;;
        suse) _has_cmd zypper && pm="zypper" || pm="none" ;;
        nix) _has_cmd nix-env && pm="nix" || pm="none" ;;
        *)
            if _has_cmd apt; then pm="apt"
            elif _has_cmd dnf; then pm="dnf"
            elif _has_cmd pacman; then pm="pacman"
            elif _has_cmd apk; then pm="apk"
            elif _has_cmd zypper; then pm="zypper"
            elif _has_cmd brew; then pm="brew"
            else pm="none"; fi ;;
    esac

    # Cache the result
    _CACHED_LINUX_PKG_MANAGER="$pm"
    echo "$pm"
}

_get_install_cmd() {
    local tool="$1"
    local pm="$(_get_package_manager)"
    case "$pm" in
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
# CLIPBOARD COMMAND
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
# WSL-SPECIFIC CONFIGURATION
# ----------------------------------------------------------

if _is_wsl; then
    _log DEBUG "WSL environment detected"
    export BROWSER="wslview"
    export WINHOME="/mnt/c/Users/${USER}"

    # Fix: Check directory exists first, then get socket (glob fails with multiple files)
    if [[ -z "$WSL_INTEROP" && -d /run/WSL ]]; then
        local wsl_socket
        wsl_socket=$(ls /run/WSL/* 2>/dev/null | head -1)
        [[ -n "$wsl_socket" ]] && export WSL_INTEROP="$wsl_socket"
    fi
fi

# ----------------------------------------------------------
_log DEBUG "ZSH Linux Platform Library loaded"
