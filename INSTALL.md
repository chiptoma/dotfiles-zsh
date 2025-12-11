# Installation Guide

## Quick Start

```bash
# Clone and run the installer
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
~/.config/zsh/install.sh
```

That's it! The installer handles everything automatically.

---

## Installer Options

```bash
./install.sh              # Interactive installation
./install.sh --yes        # Non-interactive (accept all defaults)
./install.sh --check      # Verify existing installation
./install.sh --update     # Update to latest version
./install.sh --uninstall  # Remove configuration
./install.sh --help       # Show all options
```

## What the Installer Does

1. **Checks Requirements** - Verifies zsh, git, curl are installed
2. **Installs Oh My Zsh** - If not already present
3. **Backs Up Existing Config** - Saves ~/.zshrc, ~/.zshenv to timestamped backup
4. **Installs Configuration** - Symlinks (recommended) or copies files
5. **Configures ZDOTDIR** - Creates ~/.zshenv pointing to config
6. **Installs Optional Tools** - fzf, eza, bat, ripgrep, fd, zoxide, starship, atuin
7. **Creates .zshlocal** - For your personal customizations
8. **Verifies Installation** - Checks all components are in place

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

## Optional Tools

The installer can install these recommended tools:

| Tool | Purpose | Install Method |
|------|---------|----------------|
| **fzf** | Fuzzy finder | Package manager |
| **eza** | Modern ls | brew/pacman/dnf or cargo |
| **bat** | Better cat | Package manager |
| **ripgrep** | Fast grep | Package manager |
| **fd** | Modern find | Package manager |
| **zoxide** | Smart cd | Package manager |
| **starship** | Cross-shell prompt | brew/pacman/dnf or script |
| **atuin** | Shell history sync | brew/pacman or script |

### Manual Tool Installation

**macOS:**
```bash
brew install fzf eza bat ripgrep fd zoxide starship atuin
```

**Ubuntu/Debian:**
```bash
sudo apt install fzf bat ripgrep fd-find zoxide
# eza, starship, atuin need alternative install methods
curl -sS https://starship.rs/install.sh | sh
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
cargo install eza
```

**Arch:**
```bash
sudo pacman -S fzf eza bat ripgrep fd zoxide starship atuin
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
export ZSH_LOG_LEVEL=DEBUG
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
