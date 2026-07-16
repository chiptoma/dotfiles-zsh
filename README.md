# ZSH Configuration

[![CI](https://github.com/chiptoma/dotfiles-zsh/actions/workflows/test-quality.yml/badge.svg)](https://github.com/chiptoma/dotfiles-zsh/actions/workflows/test-quality.yml)
[![Platforms](https://github.com/chiptoma/dotfiles-zsh/actions/workflows/test-platforms.yml/badge.svg)](https://github.com/chiptoma/dotfiles-zsh/actions/workflows/test-platforms.yml)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Version](https://img.shields.io/github/v/release/chiptoma/dotfiles-zsh)](https://github.com/chiptoma/dotfiles-zsh/releases/latest)

A modular, modern ZSH configuration with security-first defaults, lazy loading, and cross-platform support. No framework dependency — plugins are self-managed git clones.

## Features

| Feature | Description |
|---------|-------------|
| **Modular Architecture** | Enable/disable features independently via `Z_*_ENABLED` flags |
| **Self-Managed Plugins** | zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab — no Oh My Zsh |
| **Lazy Loading** | Deferred initialization for zoxide, nvm, pyenv, rbenv |
| **Security First** | History filtering, safe aliases, ownership verification |
| **Cross-Platform** | macOS (Intel/Apple Silicon) and Linux with auto-detection |
| **XDG Compliant** | Respects XDG Base Directory specification, with an XDG guardian |
| **Performance** | 107ms interactive startup (measured with hyperfine), cached tool init |

## Quick Start

```bash
# Option 1: Clone and install (recommended)
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
~/.config/zsh/install.sh

# Option 2: One-liner via curl
curl -fsSL https://raw.githubusercontent.com/chiptoma/dotfiles-zsh/main/install.sh | bash
```

The installer:
- Configures ZDOTDIR and creates XDG directories
- Clones the shell plugins (zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab) into `~/.local/share/zsh/plugins`
- Offers an interactive checkbox menu of optional tools (grouped essential / recommended / extra)
- Backs up any existing config to `~/.zsh-backup-<timestamp>` before touching it

See [INSTALL.md](INSTALL.md) for detailed instructions, all flags, and unattended installs.

## Architecture

```
~/.config/zsh/
├── .zshenv                 # Entry point: XDG, core lib, registry, path, environment
├── .zshrc                  # Interactive: modules, plugins, keybindings
├── .zshlocal               # User customizations (gitignored)
│
├── modules/                # Numbered by load order
│   ├── 01_path.zsh         # PATH management, platform paths
│   ├── 02_environment.zsh  # ENV vars, XDG dirs, editor detection
│   ├── 03_lazy.zsh         # Deferred tool initialization
│   ├── 04_completion.zsh   # Tab completion, caching
│   ├── 05_history.zsh      # History management, security filtering
│   ├── 06_aliases.zsh      # Command aliases, modern replacements
│   └── 07_keybindings.zsh  # Key bindings, atuin/fzf integration
│
├── lib/
│   ├── core/               # Foundational infrastructure
│   │   ├── logging.zsh     # _log with levels, colors, caller info
│   │   ├── ui.zsh          # Shared output helpers
│   │   ├── helpers.zsh     # _has_cmd, _safe_source, _cache_eval
│   │   ├── profile.zsh     # Opt-in startup profiler
│   │   └── platform/       # OS detection, macOS/Linux/BSD helpers
│   ├── functions/          # User-facing z_* commands (auto-discovered)
│   ├── plugins/
│   │   ├── index.zsh       # Plugin loader (self-managed clones)
│   │   └── vendor/         # Vendored widgets (dirhistory, sudo)
│   └── registry/           # Tool knowledge: paths, env vars, tools.dat catalog
│
├── tools/                  # Shipped tool configs (manifest-driven)
├── completions/            # Custom completions
├── ansible/                # Ansible role + playbook for fleet installs
├── tests/                  # Test suites (see docs/TESTING.md)
└── Justfile                # Task runner — single entry for dev tasks
```

## Documentation

- **[docs/COMMANDS.md](docs/COMMANDS.md)** — full command reference (generated via `just docs-commands`)
- **[docs/TESTING.md](docs/TESTING.md)** — test layers and the `just` workflow
- **[docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md)** — personalizing via `.zshlocal`
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — debugging guide

### Interactive Modules

| Module | Docs | Description |
|--------|------|-------------|
| **History** | [docs/history.md](docs/history.md) | Security filtering, interactive search, statistics |
| **Aliases** | [docs/aliases.md](docs/aliases.md) | 75+ aliases organized by category |
| **Functions** | [docs/functions.md](docs/functions.md) | 30+ utility functions (calc, weather, ports, etc.) |
| **Keybindings** | [docs/keybindings.md](docs/keybindings.md) | Atuin, navigation, editing shortcuts |
| **Completion** | [docs/completion.md](docs/completion.md) | Smart tab completion with caching |

### Core Infrastructure

| Module | Docs | Description |
|--------|------|-------------|
| **PATH** | [docs/path.md](docs/path.md) | Intelligent PATH with 50+ dev tools |
| **Environment** | [docs/environment.md](docs/environment.md) | XDG compliance, editor detection, SSH agent |
| **Lazy Loading** | [docs/lazy.md](docs/lazy.md) | Deferred init for fast startup |
| **Platform** | [docs/platform.md](docs/platform.md) | macOS/Linux detection and helpers |
| **Logging** | [docs/logging.md](docs/logging.md) | Debug levels, colors, caller info |
| **Core** | [docs/core.md](docs/core.md) | Core helpers (`_has_cmd`, `_cache_eval`) |

## Performance

Interactive startup is measured with hyperfine (`just bench`):

| Configuration | Mean startup |
|---------------|--------------|
| Previous (Oh My Zsh based) | 173ms |
| Current (self-managed plugins) | **107ms** |

Contributing factors: no framework overhead, cached `eval` of tool init (starship, atuin, zoxide, fzf), lazy loading of version managers, and a compiled completion dump.

Profile your own startup:

```bash
Z_PROFILE_STARTUP=true zsh -ic z_profile   # Per-stage timing breakdown
Z_PROFILE_STARTUP=zprof zsh -ic exit       # Function-level (zprof) report
```

## Plugins

Plugins are plain git clones in `~/.local/share/zsh/plugins`, installed by the installer and loaded by `lib/plugins/index.zsh` — no plugin manager required:

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — inline history suggestions
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) — command colorization (loads last, from `.zshrc`)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab) — fzf-powered completion menu (loads right after `compinit`)

Small widgets (`dirhistory`, `sudo`) are vendored in `lib/plugins/vendor/`. Clones made by older versions of this config into the legacy Oh My Zsh custom-plugins directory are still honored as a fallback for one release.

## Modules

### Essential (Always Load)

| Module | Docs | Purpose |
|--------|------|---------|
| Logging | [docs/logging.md](docs/logging.md) | `_log` function with levels, colors, caller info |
| Core | [docs/core.md](docs/core.md) | Core helpers: `_has_cmd`, `_safe_source`, `_cache_eval` |
| Platform | [docs/platform.md](docs/platform.md) | OS-specific detection and paths |
| Functions | [docs/functions.md](docs/functions.md) | User-facing `z_*` functions |

### Optional (Toggleable)

| Module | Docs | Default | Purpose |
|--------|------|---------|---------|
| Environment | [docs/environment.md](docs/environment.md) | enabled | XDG dirs, editor detection, tool configs |
| Path | [docs/path.md](docs/path.md) | enabled | PATH management, dev tools, version managers |
| Lazy | [docs/lazy.md](docs/lazy.md) | enabled | Deferred init for slow tools |
| Completion | [docs/completion.md](docs/completion.md) | enabled | Tab completion with caching |
| History | [docs/history.md](docs/history.md) | enabled | History with security filtering |
| Aliases | [docs/aliases.md](docs/aliases.md) | enabled | Modern tool replacements |
| Keybindings | [docs/keybindings.md](docs/keybindings.md) | enabled | Key bindings (atuin, navigation) |

## Configuration Reference

All options can be set in `.zshlocal` or exported before sourcing.

### Global

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_LOG_LEVEL` | `WARN` | Log verbosity: `DEBUG`, `INFO`, `WARN`, `ERROR`, `NONE` |

### Module Toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_ENVIRONMENT_ENABLED` | `true` | Environment module |
| `Z_PATH_ENABLED` | `true` | PATH module |
| `Z_LAZY_ENABLED` | `true` | Lazy loading module |
| `Z_COMPLETION_ENABLED` | `true` | Completion module |
| `Z_HISTORY_ENABLED` | `true` | History module |
| `Z_ALIASES_ENABLED` | `true` | Aliases module |
| `Z_KEYBINDINGS_ENABLED` | `true` | Keybindings module |

### Lazy Loading

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_LAZY_ZOXIDE` | `true` | Lazy load zoxide |
| `Z_LAZY_NVM` | `true` | Lazy load nvm |
| `Z_LAZY_PYENV` | `true` | Lazy load pyenv |
| `Z_LAZY_RBENV` | `true` | Lazy load rbenv |

### Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_ENVIRONMENT_XDG_STRICT` | `true` | Enforce XDG for all tools |
| `Z_ENVIRONMENT_SSH_MINIMAL` | `true` | Minimal env in SSH sessions |
| `Z_ENVIRONMENT_SSH_AGENT` | `true` | Auto-detect SSH agent socket |
| `Z_LOCALE_OVERRIDE` | empty | Override system locale |
| `Z_GUI_EDITORS_ORDER` | `"surf cursor code"` | GUI editor preference |
| `Z_TERMINAL_EDITORS_ORDER` | `"nvim vim vi"` | Terminal editor preference |

### PATH

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_PATH_HOMEBREW` | `true` | Detect and init Homebrew |
| `Z_PATH_CLEAN` | `true` | Remove non-existent dirs |
| `Z_PATH_PROJECT_BIN` | `false` | Add `./bin`, `./node_modules/.bin` |
| `Z_PATH_SSH_MINIMAL` | `true` | Minimal PATH in SSH |
| `Z_PATH_FORCE_MINIMAL` | `false` | Force minimal PATH always |

### History

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_HISTORY_SIZE` | `100000` | Commands in memory |
| `Z_HISTORY_SAVE_SIZE` | `100000` | Commands saved to file |
| `Z_HISTORY_SECURITY_FILTER` | `true` | Filter sensitive commands |

### Completion

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_COMPLETION_TTL` | `86400` | Compdump TTL in seconds (24h) |
| `Z_COMPLETION_MENU_SELECT` | `true` | Arrow-key menu selection |

### Aliases

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_ALIASES_MODERN_TOOLS` | `true` | Use eza, bat, ripgrep, etc. |
| `Z_ALIASES_SAFETY_PROMPTS` | `true` | Confirm destructive ops |

### XDG Guardian

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_XDG_GUARDIAN_ENABLED` | `true` | Scan `$HOME` for XDG-movable dotfiles |
| `Z_XDG_GUARDIAN_MODE` | `notify` | `notify` (one-line summary), `interactive`, or `off` |
| `Z_XDG_GUARDIAN_INTERVAL` | `86400` | Seconds between scans (24h) |

### Update Check

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_UPDATE_CHECK_ENABLED` | `true` | Check for updates on shell launch |
| `Z_UPDATE_CHECK_INTERVAL` | `86400` | Seconds between checks (24h) |
| `Z_UPDATE_AUTO_FETCH` | `true` | Fetch updates in background |

### Other

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_VERIFY_FILE_OWNERSHIP` | `false` | Check file ownership before sourcing |
| `Z_PROFILE_STARTUP` | unset | `true` = per-stage timings, `zprof` = function-level report |

## Customization

Create `.zshlocal` (gitignored) for personal settings:

```bash
cp examples/zshlocal .zshlocal
$EDITOR .zshlocal
```

Example customizations:

```bash
# Directory shortcuts
alias dev='cd ~/Development'
alias prj='cd ~/Projects'

# Enable project-local binaries
export Z_PATH_PROJECT_BIN=true

# Override locale
export Z_LOCALE_OVERRIDE="en_US.UTF-8"

# Debug mode (see all module loading)
export Z_LOG_LEVEL=DEBUG

# Disable lazy loading for specific tools
export Z_LAZY_ZOXIDE=false
```

## Key Bindings

| Key | Action |
|-----|--------|
| `Up/Down` | Atuin history search (if installed) |
| `Ctrl-R` | Interactive history search |
| `Alt-Up/Down` | Directory history navigation |
| `Ctrl-Backspace` | Delete word backward |
| `Home/End` | Beginning/end of line |

## Useful Commands

The full command reference lives in [docs/COMMANDS.md](docs/COMMANDS.md) (or run `help` in the shell). Highlights:

| Alias | Command | Description |
|-------|---------|-------------|
| `lazy` | `z_lazy_status` | Show lazy loading status |
| `zupdate` | `z_update` | Update to latest version |
| `zversion` | `z_version` | Show current version |
| `zpath` | `z_path_show` | Display PATH entries |
| `zpathdebug` | `z_path_debug` | PATH diagnostics |
| `zhiststats` | `z_history_stats` | Top commands chart |
| `als` | `z_alias_browser` | Interactive alias browser (fzf) |
| `sshagent` | `z_ssh_agent` | SSH agent provider, socket, keys |
| `dotbackup` / `dotrestore` | `z_dotfiles_backup` / `z_dotfiles_restore` | Snapshot / restore managed dotfiles |
| `copypath` / `copyfile` | `z_copypath` / `z_copyfile` | Copy path / file contents to clipboard |
| `gitignore` | `z_gitignore` | Generate .gitignore from templates |
| `profile` | `z_profile` | Startup timing breakdown |
| `envinfo` | `z_env_info` | Editor/pager/viewer configuration |

### Popular Aliases (see [docs/aliases.md](docs/aliases.md) for all aliases)

| Alias | Expansion | Category |
|-------|-----------|----------|
| `gs` | `git status --short --branch` | Git |
| `gaa` | `git add --all` | Git |
| `gcm` | `git commit -m` | Git |
| `gps` | `git push` | Git |
| `..` / `...` | `cd ..` / `cd ../..` | Navigation |
| `mkcd` | Create dir and cd into it | Navigation |
| `lt` | `eza --tree --level=2 --icons` | Modern tools |
| `G` | `\| grep` (global alias) | Piping |

## Development

All dev, test, and maintenance tasks run through the [Justfile](Justfile):

```bash
just            # List all recipes
just test       # Lint + unit + smoke (safe on any machine)
just bench      # Benchmark interactive startup with hyperfine
```

See [docs/TESTING.md](docs/TESTING.md) for the full test-layer breakdown and [CONTRIBUTING.md](CONTRIBUTING.md) for conventions.

## Troubleshooting

**Commands not found after install:**
```bash
exec zsh  # Restart shell completely
```

**Debug module loading:**
```bash
export Z_LOG_LEVEL=DEBUG
exec zsh
```

**Check lazy loading status:**
```bash
z_lazy_status
```

**PATH issues:**
```bash
zpathdebug     # Show diagnostics
zpathclean     # Remove non-existent entries
```

**Reset completion cache:**
```bash
rm -f ~/.cache/zsh/completion/zcompdump*
exec zsh
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the full guide.

## Dependencies

**Required:**
- ZSH 5.8+
- git (for plugin clones and updates)

**Shell plugins (cloned automatically by the installer):**
- zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab

**Essential tools (installed by default):**
- [starship](https://starship.rs/) - Cross-shell prompt with git status
- [atuin](https://atuin.sh/) - Shell history search and sync

**Recommended (selectable during install):**
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder (Ctrl+R, Ctrl+T)
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smarter cd
- [eza](https://github.com/eza-community/eza) - Modern ls with icons
- [bat](https://github.com/sharkdp/bat) - Modern cat with syntax highlighting
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast grep
- [fd](https://github.com/sharkdp/fd) - Modern find

The full 29-tool catalog lives in `lib/registry/tools.dat`.

```bash
# macOS
brew install starship atuin fzf zoxide eza bat ripgrep fd

# Linux (Ubuntu/Debian) - see INSTALL.md for details
# Note: bat→batcat, fd→fdfind on Debian-based systems
```

## License

MIT
