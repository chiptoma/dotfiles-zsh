# Installation Guide

## Quick Start

```bash
# Option 1: Clone and run (recommended)
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
~/.config/zsh/install.sh

# Option 2: One-liner via curl
curl -fsSL https://raw.githubusercontent.com/chiptoma/dotfiles-zsh/main/install.sh | bash
```

That's it! The installer handles everything automatically. Installing from a fork or a CI mirror? Set `ZSH_DOTFILES_REPO_URL` before the curl-pipe command.

---

## Installer Options

### Installation options

| Flag | Description |
|------|-------------|
| `--help`, `-h` | Show this help message |
| `--version`, `-v` | Show version number |
| `--yes`, `-y` | Non-interactive mode (accept defaults) |
| `--quiet`, `-q` | Minimal output (implies `--yes`) |
| `--dry-run`, `-n` | Show what would be done without making changes |
| `--verbose` | Show detailed debug output |
| `--symlink` | Symlink the repo into place (development setups) |
| `--copy` | Copy files into place (default when unattended) |
| `--default-shell` | Set zsh as default shell without asking |
| `--no-default-shell` | Never touch the default shell |

### Installation profiles

| Flag | Description |
|------|-------------|
| `--minimal` | Core ZSH + plugins only (no optional tools) |
| `--full` | Install all optional tools automatically |
| `--skip-tools` | Skip optional tools installation step |
| `--tools TOOLS` | Install specific tools (comma-separated). Full catalog: `lib/registry/tools.dat` (starship, atuin, eza, bat, fzf, zoxide, delta, lazygit, btm, dust, ...) |

### Maintenance

| Flag | Description |
|------|-------------|
| `--check`, `-c` | Verify existing installation |
| `--update` | Update to latest version (git pull) |
| `--repair`, `--fix` | Repair broken installation |
| `--restore [DIR]` | Restore dotfiles from a backup (newest by default) |
| `--uninstall`, `-u` | Uninstall the configuration |

### Advanced

| Flag | Description |
|------|-------------|
| `--user USERNAME` | Run as specified user (for Docker testing) |

### Environment variables

| Variable | Description |
|----------|-------------|
| `NO_COLOR` | Disable colored output |
| `XDG_CONFIG_HOME` | Override config directory (default: `~/.config`) |
| `XDG_DATA_HOME` | Override data directory (default: `~/.local/share`) |
| `ZSH_DOTFILES_REPO_URL` | Override repo URL for curl-pipe installs (forks/CI) |

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success (warnings possible, listed in the summary) |
| `1` | Installation error (rollback attempted) |
| `2` | Usage error (bad flag or argument) |
| `3` | Preflight failure (missing dependency, no network) |

### Examples

```bash
install.sh                        # Interactive installation
install.sh --yes                  # Automated with defaults
install.sh --minimal --yes        # Minimal install (no optional tools)
install.sh --full --yes           # Full install with all tools
install.sh --tools fzf,eza,bat    # Install only specific tools
install.sh --skip-tools --yes     # Install config without optional tools
install.sh --repair               # Fix broken installation
install.sh --check                # Verify installation health
```

---

## Choosing Tools

The installer reads its 29-tool catalog from `lib/registry/tools.dat`, where every tool is tiered:

- **essential** — `starship` (prompt), `atuin` (history)
- **recommended** — `eza`, `bat`, `fd`, `ripgrep`, `sd`, `fzf`, `zoxide`, `yazi`, `dust`, `duf`, `btm`, `delta`, `lazygit`, `gh`, `tldr`, `topgrade`
- **extra** — `procs`, `fastfetch`, `gping`, `trippy`, `xh`, `bandwhich`, `hyperfine`, `direnv`, `yq`, `just`, `mas` (macOS only)

**Interactive runs** get a checkbox menu of every missing tool, grouped by tier. Toggle entries by number, `a`/`n` for all/none, `p` to cycle the preset (minimal → recommended → full), Enter to confirm.

**Unattended runs** (`--yes`, `--quiet`, or an explicit profile flag) select by tier: the default profile installs essential + recommended; `--minimal` installs essential only; `--full` installs everything; `--tools a,b,c` installs exactly the named tools.

Shipped tool configs (starship, atuin, bat, ripgrep, delta, lazygit, btm, fastfetch, tldr) are installed per `tools/manifest.dat` — only for tools that are actually present, with any pre-existing config backed up first.

---

## SSH / Headless Server Quick-Start

For servers, containers, or CI environments where you want the framework without optional tools:

```bash
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
~/.config/zsh/install.sh --skip-tools --yes
```

This gives you:
- Full modular framework (PATH, environment, history, aliases, functions)
- Security-filtered history
- XDG-compliant directory structure
- SSH minimal mode (auto-detected — lighter env for remote sessions)
- No optional tool prompts or downloads

Add tools later at any time:

```bash
~/.config/zsh/install.sh --tools starship,fzf
```

---

## Unattended / Ansible

In unattended mode (`--yes` or `--quiet`) the installer never execs a new shell and never changes your default shell — pass `--default-shell` to opt in, or run `chsh -s $(command -v zsh)` yourself. Files are copied (not symlinked) by default so the install survives repo moves; pass `--symlink` to override.

For fleet installs, an Ansible role is included:

```bash
ansible-playbook -i inventory ansible/playbook.yml
```

See [ansible/README.md](ansible/README.md) for role variables (repo/fork, install method, tool profile, default shell) and idempotence notes.

---

## What the Installer Does

1. **Checks requirements** - Verifies zsh, git, curl, network connectivity
2. **Backs up existing config** - Everything it will touch (dotfiles and tool configs) goes to `~/.zsh-backup-<timestamp>/` with a `MANIFEST`
3. **Installs configuration** - Symlinks (`--symlink`) or copies files, and sets ZDOTDIR via `~/.zshenv`
4. **Clones shell plugins** - zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab into `~/.local/share/zsh/plugins` (existing clones in the legacy Oh My Zsh custom dir are migrated)
5. **Installs tools** - Interactive checkbox menu, or tier rules when unattended
6. **Installs tool configs** - Per `tools/manifest.dat`, for tools that are present
7. **Creates .zshlocal** - For your personal customizations
8. **Verifies installation** - Checks all components are in place

### Backups

- Every run that changes files creates `~/.zsh-backup-<timestamp>/` with a `MANIFEST` mapping each original path to its backup copy (including tool configs).
- Restore the newest backup with `install.sh --restore`, or a specific one with `install.sh --restore ~/.zsh-backup-<timestamp>`.
- When more than five backups accumulate, interactive runs offer to prune the oldest (the newest five are always kept; unattended runs never delete backups).

---

## Manual Installation

If you prefer not to use the installer:

### 1. Clone Configuration

```bash
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
```

### 2. Set ZDOTDIR

```bash
echo 'export ZDOTDIR="$HOME/.config/zsh"' > ~/.zshenv
```

### 3. Clone Plugins (Optional)

```bash
P=~/.local/share/zsh/plugins && mkdir -p "$P"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$P/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$P/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$P/fzf-tab"
```

The framework works without them — missing plugins are simply skipped.

### 4. Restart Shell

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

## Manual Tool Installation

**macOS:**
```bash
# Essential
brew install starship atuin

# Recommended (subset)
brew install fzf eza bat ripgrep fd zoxide
```

**Ubuntu/Debian:**
```bash
# Essential (via install scripts - most reliable)
curl -sS https://starship.rs/install.sh | sh
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)

# Recommended (subset)
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
z_update
```

### Manual Update

```bash
cd ~/.config/zsh
git pull
exec zsh
```

### Check Version

```bash
z_version
# Output: ZSH Configuration v0.1.1
#         Git: main @ abc1234
```

---

## Troubleshooting

### Commands Not Found

Restart your shell completely:
```bash
exec zsh
```

### Plugins Not Loading

Check the clones exist and re-run the installer if not:
```bash
ls ~/.local/share/zsh/plugins
~/.config/zsh/install.sh --repair
```

### Slow Startup

Enable debug mode to see what's slow:
```bash
export Z_LOG_LEVEL=DEBUG
exec zsh
```

Or profile per stage:
```bash
Z_PROFILE_STARTUP=true zsh -ic z_profile
```

### Verify Health

```bash
~/.config/zsh/install.sh --check
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the full guide.

---

## Uninstalling

```bash
~/.config/zsh/install.sh --uninstall
```

This removes:
- Configuration directory (`~/.config/zsh`)
- ZDOTDIR setting (`~/.zshenv`)
- Optionally: data directories (history, cache)
