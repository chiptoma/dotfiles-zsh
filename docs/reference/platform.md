# Platform Module

Cross-platform detection and OS-specific configuration for macOS, Linux, and BSD.

## Overview

The platform module automatically detects your operating system and loads the appropriate configuration:

- **macOS** - Homebrew paths, Apple Silicon detection, macOS-specific utilities
- **Linux** - Distribution detection, package manager helpers, Snap/Flatpak paths
- **BSD** - FreeBSD/OpenBSD/NetBSD detection, package manager helpers

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
| `MACOS_VERSION` | `sonoma` | Human-readable macOS version |
| `MACOS_ARCH` | `arm64` | CPU architecture |
| `MACOS_CHIP` | `apple_silicon` | Chip type (`apple_silicon` or `intel`) |
| `BROWSER` | `open` | Default browser command |
| `HOMEBREW_PREFIX` | `/opt/homebrew` | Homebrew installation path |

```bash
# Use in your scripts
echo "Running macOS $MACOS_VERSION on $MACOS_CHIP"
# Output: Running macOS sonoma on apple_silicon
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

#### `z_killapp <app>`

Quit an application gracefully.

```bash
killapp Safari       # Quit Safari
killapp "Google Chrome"  # Quit Chrome
```

Tries AppleScript first, falls back to `pkill`.

#### `z_wifi_name`

Get current Wi-Fi network name.

```bash
wifi
# Output: MyNetwork
```

#### `z_wifi_password [network]`

Show Wi-Fi password (requires admin access).

```bash
wifipass              # Password for current network
wifipass "OtherNet"   # Password for specific network
```

#### `z_check_tools`

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

Automatically detects, in order:

1. **1Password SSH Agent** - `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
2. **GPG Agent** - `$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh`
3. **Pre-existing `$SSH_AUTH_SOCK`** - the macOS launchd agent, kept as fallback

Sets `SSH_AUTH_SOCK` appropriately. Inspect with `sshagent`.

## Linux Configuration

### Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `LINUX_DISTRO` | `ubuntu` | Distribution ID from `/etc/os-release` |
| `LINUX_FAMILY` | `debian` | Distribution family (debian, rhel, arch, etc.) |
| `LINUX_ARCH` | `x86_64` | CPU architecture |
| `DISPLAY_SERVER` | `wayland` | Display server (`wayland`, `x11`, or `none`) |
| `XDG_RUNTIME_DIR` | `/run/user/1000` | Runtime directory |
| `DBUS_SESSION_BUS_ADDRESS` | `unix:path=...` | D-Bus socket path |
| `BROWSER` | `wslview` | Browser command (WSL) |

```bash
# Use in your scripts
echo "Running $LINUX_DISTRO ($LINUX_FAMILY) on $DISPLAY_SERVER"
# Output: Running ubuntu (debian) on wayland
```

### Distribution Family Detection

The platform module internally detects your Linux distribution family for package manager selection.

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

Automatically detects, in order:

1. **1Password SSH Agent** - `~/.1password/agent.sock`
2. **GPG Agent** - `$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh`
3. **GNOME Keyring** - `$XDG_RUNTIME_DIR/keyring/ssh`
4. **Pre-existing `$SSH_AUTH_SOCK`** - kept when it points at a valid socket

### WSL Configuration

When running in WSL:

```bash
export BROWSER="wslview"
export WINHOME="/mnt/c/Users/$USER"
```

## BSD Configuration

### Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `BSD_VARIANT` | `freebsd` | BSD variant (`freebsd`, `openbsd`, `netbsd`) |
| `BSD_VERSION` | `14.0` | BSD version string |
| `BSD_ARCH` | `amd64` | CPU architecture |

```bash
# Use in your scripts
echo "Running $BSD_VARIANT $BSD_VERSION on $BSD_ARCH"
# Output: Running freebsd 14.0 on amd64
```

### Package Manager Detection

```bash
_get_install_cmd fzf
# Output: pkg install fzf        (FreeBSD)
# Output: pkg_add fzf            (OpenBSD)
# Output: pkgin install fzf      (NetBSD)
```

### Clipboard Detection (BSD)

| Environment | Command |
|-------------|---------|
| X11 (xclip) | `xclip -selection clipboard` |
| X11 (xsel) | `xsel --clipboard --input` |

## Cross-Platform Safety

All platform detection functions are defined in `detect.zsh` (loaded unconditionally) using `$OSTYPE` checks. They naturally return non-zero on the wrong platform — no stubs needed. Any code can safely call any `_is_*` function regardless of which platform is active.

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
| Detection | [lib/core/platform/detect.zsh](../../lib/core/platform/detect.zsh) |
| macOS | [lib/core/platform/macos.zsh](../../lib/core/platform/macos.zsh) |
| Linux | [lib/core/platform/linux.zsh](../../lib/core/platform/linux.zsh) |
| BSD | [lib/core/platform/bsd.zsh](../../lib/core/platform/bsd.zsh) |

Only one file is loaded based on `$OSTYPE`.
