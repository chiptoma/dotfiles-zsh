# Installation Guide

## Quick Start

```bash
# Option 1: Clone and run (recommended)
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
~/.config/zsh/install.sh

# Option 2: One-liner via curl
curl -fsSL https://raw.githubusercontent.com/chiptoma/dotfiles-zsh/main/install.sh | bash
```

That's it! The installer handles everything automatically.

---

## Installer Options

### Basic Options
```bash
./install.sh              # Interactive installation
./install.sh --yes, -y    # Non-interactive (accept all defaults)
./install.sh --quiet, -q  # Minimal output (implies --yes)
./install.sh --dry-run, -n # Show what would be done without changes
./install.sh --help, -h   # Show all options
./install.sh --version, -v # Show version number
```

### Installation Profiles
```bash
./install.sh --minimal    # Core ZSH + Oh My Zsh only (essential tools only)
./install.sh --full       # Install all tools automatically
./install.sh --skip-tools # Skip recommended tools (essential still installed)
./install.sh --tools fzf,eza,bat  # Install only specific tools
```

**Tool Tiers:**
- **Essential** (always installed): `starship`, `atuin` - Required for proper shell experience
- **Recommended** (default Y): `fzf`, `eza`, `bat`, `ripgrep`, `fd`, `zoxide` - Power user tools
- **Extra** (--full only): `yazi` - File manager

### Maintenance
```bash
./install.sh --check, -c  # Verify existing installation
./install.sh --update     # Update to latest version (git pull)
./install.sh --repair     # Repair broken installation
./install.sh --uninstall, -u # Remove configuration
```

### Environment Variables
```bash
NO_COLOR=1 ./install.sh   # Disable colored output
XDG_CONFIG_HOME=~/.config ./install.sh  # Override config directory
```

## What the Installer Does

1. **Checks Requirements** - Verifies zsh, git, curl, network connectivity
2. **Installs Oh My Zsh** - If not already present
3. **Backs Up Existing Config** - Saves ~/.zshrc, ~/.zshenv to timestamped backup
4. **Installs Configuration** - Symlinks (from repo) or copies files
5. **Configures ZDOTDIR** - Creates ~/.zshenv pointing to config
6. **Installs Essential Tools** - starship (prompt), atuin (history) - always installed
7. **Installs Recommended Tools** - fzf, eza, bat, ripgrep, fd, zoxide (prompted)
8. **Creates .zshlocal** - For your personal customizations
9. **Verifies Installation** - Checks all components are in place

---

## Manual Installation

If you prefer not to use the installer:

### 1. Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 2. Clone Configuration

```bash
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
```

### 3. Set ZDOTDIR

```bash
echo 'export ZDOTDIR="$HOME/.config/zsh"' > ~/.zshenv
```

### 4. Move Oh My Zsh (Optional)

```bash
mv ~/.oh-my-zsh ~/.local/share/oh-my-zsh
```

### 5. Restart Shell

```bash
exec zsh
```

---

## Platform Support

| Platform | Package Manager | Status |
|----------|-----------------|--------|
| macOS (Intel) | Homebrew | ✅ Full support |
| macOS (Apple Silicon) | Homebrew | ✅ Full support |
| Ubuntu/Debian | apt | ✅ Full support |
| Fedora/RHEL | dnf | ✅ Full support |
| Arch Linux | pacman | ✅ Full support |
| Alpine | apk | ⚠️ Some tools via cargo |
| WSL | apt/dnf | ✅ Full support |

---

## Tools

### Essential Tools (Always Installed)

These are required for a proper shell experience:

| Tool | Purpose | Install Method |
|------|---------|----------------|
| **starship** | Cross-shell prompt with git status | brew/pacman/dnf or script |
| **atuin** | Shell history search and sync | brew/pacman or script |

### Recommended Tools (Prompted)

Power user tools that enhance productivity:

| Tool | Purpose | Install Method |
|------|---------|----------------|
| **fzf** | Fuzzy finder (Ctrl+R, Ctrl+T) | Package manager |
| **eza** | Modern ls with icons | brew/pacman/dnf or cargo |
| **bat** | Better cat with syntax highlighting | Package manager |
| **ripgrep** | Fast grep (10x faster) | Package manager |
| **fd** | Modern find | Package manager |
| **zoxide** | Smart cd (learns your habits) | Package manager |

### Extra Tools (--full only)

| Tool | Purpose | Install Method |
|------|---------|----------------|
| **yazi** | Terminal file manager | brew/pacman or script |

### Manual Tool Installation

**macOS:**
```bash
# Essential
brew install starship atuin

# Recommended
brew install fzf eza bat ripgrep fd zoxide
```

**Ubuntu/Debian:**
```bash
# Essential (via install scripts - most reliable)
curl -sS https://starship.rs/install.sh | sh
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)

# Recommended
sudo apt install fzf bat ripgrep fd-find zoxide
cargo install eza  # or download from GitHub releases
```

> **Note:** On Ubuntu/Debian, `bat` is installed as `batcat` and `fd` is installed as `fdfind`. The shell config handles this automatically with aliases.

**Arch:**
```bash
sudo pacman -S starship atuin fzf eza bat ripgrep fd zoxide
```

---

## Post-Installation

### Customize Settings

```bash
# Edit your personal configuration
$EDITOR ~/.config/zsh/.zshlocal
```

### Verify Installation

```bash
~/.config/zsh/install.sh --check
```

---

## Updating

### Automatic Update

```bash
# Using the install script
~/.config/zsh/install.sh --update

# Or using the shell function
zsh_update
```

### Manual Update

```bash
cd ~/.config/zsh
git pull
exec zsh
```

### Check Version

```bash
zsh_version
# Output: ZSH Configuration v1.0.0
#         Git: main @ abc1234
```

---

## Troubleshooting

### "Oh My Zsh not found"

The config expects OMZ at `~/.local/share/oh-my-zsh`:

```bash
mv ~/.oh-my-zsh ~/.local/share/oh-my-zsh
```

Or set a custom path in `.zshlocal`:
```bash
export ZSH="$HOME/.oh-my-zsh"
```

### Commands Not Found

Restart your shell completely:
```bash
exec zsh
```

### Slow Startup

Enable debug mode to see what's slow:
```bash
export Z_LOG_LEVEL=DEBUG
exec zsh
```

### Verify Health

```bash
~/.config/zsh/install.sh --check
```

---

## Uninstalling

```bash
~/.config/zsh/install.sh --uninstall
```

This removes:
- Configuration directory (`~/.config/zsh`)
- ZDOTDIR setting (`~/.zshenv`)
- Optionally: data directories (history, cache)
