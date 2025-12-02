# Platform Module

Cross-platform detection and OS-specific configuration for macOS and Linux.

## Overview

The platform module automatically detects your operating system and loads the appropriate configuration:

- **macOS** - Homebrew paths, Apple Silicon detection, macOS-specific utilities
- **Linux** - Distribution detection, package manager helpers, Snap/Flatpak paths

Only one platform file loads based on `$OSTYPE`.

## Platform Detection Functions

Available on all platforms:

| Function | Returns |
|----------|---------|
| `_is_macos` | True on macOS |
| `_is_linux` | True on Linux |
| `_is_bsd` | True on FreeBSD/OpenBSD |
| `_is_wsl` | True on Windows Subsystem for Linux |
| `_is_apple_silicon` | True on M1/M2/M3 Macs |

```bash
if _is_macos; then
    echo "Running on macOS"
elif _is_linux; then
    echo "Running on Linux"
fi

if _is_apple_silicon; then
    echo "Apple Silicon detected"
fi
```

## macOS Configuration

### Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `MACOS_VERSION` | `sonoma` | macOS version codename |
| `MACOS_ARCH` | `arm64` | CPU architecture |
| `MACOS_CHIP` | `apple_silicon` | Chip type |
| `BROWSER` | `open` | Default browser command |

### Version Detection

```bash
echo $MACOS_VERSION
# Output: sequoia, sonoma, ventura, monterey, big_sur, catalina_or_older
```

### Paths Added (macOS)

**Apple Silicon (`/opt/homebrew`):**
```
/opt/homebrew/bin
/opt/homebrew/sbin
/opt/homebrew/opt/coreutils/libexec/gnubin
```

**Intel (`/usr/local`):**
```
/usr/local/bin
/usr/local/sbin
/usr/local/opt/coreutils/libexec/gnubin
```

**Additional paths:**
```
/opt/local/bin          # MacPorts
/Library/Apple/usr/bin  # Apple tools
/System/Cryptexes/App/usr/bin  # System cryptexes (Ventura+)
/Library/Developer/CommandLineTools/usr/bin  # Xcode CLI
```

### macOS Functions

#### `zsh_killapp <app>`

Quit an application gracefully.

```bash
killapp Safari       # Quit Safari
killapp "Google Chrome"  # Quit Chrome
```

Tries AppleScript first, falls back to `pkill`.

#### `zsh_wifi_name`

Get current Wi-Fi network name.

```bash
wifi
# Output: MyNetwork
```

#### `zsh_wifi_password [network]`

Show Wi-Fi password (requires admin access).

```bash
wifipass              # Password for current network
wifipass "OtherNet"   # Password for specific network
```

#### `zsh_macos_check_tools`

Check recommended development tools.

```bash
checktools
# Output:
# Checking tools...
#   ✓ fzf - Fuzzy finder
#   ✓ ripgrep - Fast grep (rg)
#   ✗ fd - Modern find
#   ...
# Install: brew install fd
```

### SSH Agent Detection (macOS)

Automatically detects:

1. **1Password SSH Agent** - `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
2. **GPG Agent** - `~/.gnupg/S.gpg-agent.ssh`

Sets `SSH_AUTH_SOCK` appropriately.

## Linux Configuration

### Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `LINUX_DISTRO` | `ubuntu` | Distribution ID |
| `LINUX_FAMILY` | `debian` | Distribution family |
| `DISPLAY_SERVER` | `wayland` | Display server type |
| `XDG_RUNTIME_DIR` | `/run/user/1000` | Runtime directory |

### Distribution Detection

```bash
echo $LINUX_DISTRO
# Output: ubuntu, debian, fedora, arch, alpine, etc.

echo $LINUX_FAMILY
# Output: debian, rhel, arch, suse, alpine, nix, unknown
```

**Family mappings:**

| Family | Distributions |
|--------|---------------|
| `debian` | Ubuntu, Debian, Mint, Pop!_OS, Elementary, Zorin, Kali |
| `rhel` | Fedora, CentOS, RHEL, Rocky, Alma, Oracle |
| `arch` | Arch, Manjaro, EndeavourOS, Garuda |
| `suse` | openSUSE, SUSE |
| `alpine` | Alpine Linux |
| `nix` | NixOS |

### Paths Added (Linux)

```
/snap/bin                           # Snap packages
/var/lib/flatpak/exports/bin        # Flatpak (system)
~/.local/share/flatpak/exports/bin  # Flatpak (user)
~/Applications                      # AppImages
~/.local/bin                        # User binaries
~/.nix-profile/bin                  # Nix
/usr/lib/ccache                     # ccache
/usr/games                          # Games
```

**Linuxbrew (if installed):**
```
/home/linuxbrew/.linuxbrew/bin
# or
~/.linuxbrew/bin
```

### Package Manager Detection

```bash
_get_package_manager
# Output: apt, dnf, yum, pacman, apk, zypper, brew, none

_get_install_cmd fzf
# Output: sudo apt install fzf  (on Debian)
# Output: sudo dnf install fzf  (on Fedora)
# Output: sudo pacman -S fzf    (on Arch)
```

### Linux Functions

#### `zsh_linux_check_tools`

Check recommended development tools.

```bash
checktools
# Shows installed/missing tools with install command
```

### Clipboard Detection (Linux)

Automatically selects clipboard command:

| Environment | Command |
|-------------|---------|
| Wayland | `wl-copy` |
| X11 | `xclip -selection clipboard` |
| X11 (alt) | `xsel --clipboard --input` |
| WSL | `clip.exe` |

Used by history module for `Ctrl-Y` copy.

### SSH Agent Detection (Linux)

Automatically detects:

1. **GNOME Keyring** - `$XDG_RUNTIME_DIR/keyring/ssh`
2. **GPG Agent** - `$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh`
3. **KDE/systemd** - `$XDG_RUNTIME_DIR/ssh-agent.socket`

### WSL Configuration

When running in WSL:

```bash
export BROWSER="wslview"
export WINHOME="/mnt/c/Users/$USER"
```

## Cross-Platform Stubs

Each platform defines stubs for the other platform's functions:

**On macOS:**
```bash
_is_linux() { return 1 }
_is_wsl() { return 1 }
```

**On Linux:**
```bash
_is_macos() { return 1 }
_is_bsd() { return 1 }
_is_apple_silicon() { return 1 }
```

This allows code to safely call any platform function without checking first.

## Usage in Modules

```bash
# Platform-specific paths
if _is_macos; then
    export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
elif _is_linux; then
    export JAVA_HOME="/usr/lib/jvm/default-java"
fi

# Clipboard command
local clip_cmd="$(_get_clipboard_cmd)"
echo "text" | eval "$clip_cmd"

# Install instructions
if ! _has_cmd fzf; then
    echo "Install fzf: $(_get_install_cmd fzf)"
fi
```

## Files

| Platform | File |
|----------|------|
| macOS | [lib/platform/macos.zsh](../lib/platform/macos.zsh) |
| Linux | [lib/platform/linux.zsh](../lib/platform/linux.zsh) |

Only one file is loaded based on `$OSTYPE`.
