# ZSH Configuration

[![CI](https://github.com/chiptoma/dotfiles-zsh/actions/workflows/ci.yml/badge.svg)](https://github.com/chiptoma/dotfiles-zsh/actions/workflows/ci.yml)

A modular, modern ZSH configuration with security-first defaults, lazy loading, and cross-platform support.

## Features

| Feature | Description |
|---------|-------------|
| **Modular Architecture** | Enable/disable features independently via `ZSH_*_ENABLED` flags |
| **Lazy Loading** | Deferred initialization for starship, atuin, zoxide, nvm, pyenv, rbenv |
| **Security First** | History filtering, safe aliases, ownership verification |
| **Cross-Platform** | macOS (Intel/Apple Silicon) and Linux with auto-detection |
| **XDG Compliant** | Respects XDG Base Directory specification |
| **Performance** | Caching, optional compilation, minimal SSH mode |

## Quick Start

```bash
# Clone and install (handles everything automatically)
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
~/.config/zsh/install.sh
```

The installer automatically:
- Installs Oh My Zsh if missing
- Configures ZDOTDIR
- Creates XDG directories
- Offers optional tool installation (starship, fzf, etc.)

See [INSTALL.md](INSTALL.md) for detailed instructions.

## Architecture

```
~/.config/zsh/
├── .zshenv                 # Entry point: XDG, logging, utils, platform, path
├── .zshrc                  # Interactive: plugins, modules, keybindings
├── local.zsh               # User customizations (gitignored)
│
├── modules/
│   ├── logging.zsh         # Log levels, colors, caller info
│   ├── environment.zsh     # ENV vars, XDG dirs, editor detection
│   ├── path.zsh            # PATH management, platform paths
│   ├── lazy.zsh            # Deferred tool initialization
│   ├── completion.zsh      # Tab completion, caching
│   ├── history.zsh         # History management, security filtering
│   ├── aliases.zsh         # Command aliases, modern replacements
│   ├── keybindings.zsh     # Key bindings, atuin/fzf integration
│   └── compilation.zsh     # Optional .zwc compilation
│
├── lib/
│   ├── utils.zsh           # Core utilities (_has_cmd, _safe_source, etc.)
│   ├── platform/
│   │   ├── macos.zsh       # macOS-specific (Homebrew, app bundles)
│   │   └── linux.zsh       # Linux-specific (snap, flatpak)
│   └── functions/
│       ├── index.zsh       # Auto-discovery barrel
│       ├── system.zsh      # calc, weather, sysinfo
│       ├── file.zsh        # File operations
│       ├── git.zsh         # Git helpers
│       ├── docker.zsh      # Docker/container helpers
│       ├── network.zsh     # Network utilities
│       ├── python.zsh      # Python/venv helpers
│       └── introspection.zsh  # Shell debugging
│
└── completions/            # Custom completions
```

## Documentation

Detailed documentation for each module:

### Interactive Modules

| Module | Docs | Description |
|--------|------|-------------|
| **History** | [docs/history.md](docs/history.md) | Security filtering, interactive search, statistics |
| **Aliases** | [docs/aliases.md](docs/aliases.md) | 200+ aliases organized by category |
| **Functions** | [docs/functions.md](docs/functions.md) | 30+ utility functions (calc, weather, ports, etc.) |
| **Keybindings** | [docs/keybindings.md](docs/keybindings.md) | Atuin, navigation, editing shortcuts |
| **Completion** | [docs/completion.md](docs/completion.md) | Smart tab completion with caching |

### Core Infrastructure

| Module | Docs | Description |
|--------|------|-------------|
| **PATH** | [docs/path.md](docs/path.md) | Intelligent PATH with 50+ dev tools |
| **Environment** | [docs/environment.md](docs/environment.md) | XDG compliance, editor detection |
| **Lazy Loading** | [docs/lazy.md](docs/lazy.md) | Deferred init for fast startup |
| **Platform** | [docs/platform.md](docs/platform.md) | macOS/Linux detection and helpers |
| **Logging** | [docs/logging.md](docs/logging.md) | Debug levels, colors, caller info |
| **Utils** | [docs/utils.md](docs/utils.md) | Core helpers (`_has_cmd`, `_cache_eval`) |
| **Compilation** | [docs/compilation.md](docs/compilation.md) | Optional .zwc bytecode compilation |

## Modules

### Essential (Always Load)

| Module | Docs | Purpose |
|--------|------|---------|
| Logging | [docs/logging.md](docs/logging.md) | `_log` function with levels, colors, caller info |
| Utils | [docs/utils.md](docs/utils.md) | Core helpers: `_has_cmd`, `_safe_source`, `_cache_eval` |
| Platform | [docs/platform.md](docs/platform.md) | OS-specific detection and paths |
| Functions | [docs/functions.md](docs/functions.md) | User-facing `zsh_*` functions |

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
| Compilation | [docs/compilation.md](docs/compilation.md) | disabled | .zwc bytecode compilation |

## Configuration Reference

All options can be set in `local.zsh` or exported before sourcing.

### Global

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_LOG_LEVEL` | `WARN` | Log verbosity: `DEBUG`, `INFO`, `WARN`, `ERROR`, `NONE` |

### Module Toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_ENVIRONMENT_ENABLED` | `true` | Environment module |
| `ZSH_PATH_ENABLED` | `true` | PATH module |
| `ZSH_LAZY_ENABLED` | `true` | Lazy loading module |
| `ZSH_COMPLETION_ENABLED` | `true` | Completion module |
| `ZSH_HISTORY_ENABLED` | `true` | History module |
| `ZSH_ALIASES_ENABLED` | `true` | Aliases module |
| `ZSH_KEYBINDINGS_ENABLED` | `true` | Keybindings module |
| `ZSH_COMPILATION_ENABLED` | `false` | Compilation module |

### Lazy Loading

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_LAZY_STARSHIP` | `true` | Lazy load starship prompt |
| `ZSH_LAZY_ATUIN` | `true` | Lazy load atuin history |
| `ZSH_LAZY_ZOXIDE` | `true` | Lazy load zoxide |
| `ZSH_LAZY_NVM` | `true` | Lazy load nvm |
| `ZSH_LAZY_PYENV` | `true` | Lazy load pyenv |
| `ZSH_LAZY_RBENV` | `true` | Lazy load rbenv |

### Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_ENVIRONMENT_XDG_STRICT` | `true` | Enforce XDG for all tools |
| `ZSH_ENVIRONMENT_SSH_MINIMAL` | `true` | Minimal env in SSH sessions |
| `ZSH_ENVIRONMENT_SSH_AGENT` | `true` | Auto-detect SSH agent socket |
| `ZSH_LOCALE_OVERRIDE` | empty | Override system locale |
| `ZSH_GUI_EDITORS_ORDER` | `"surf cursor code"` | GUI editor preference |
| `ZSH_TERMINAL_EDITORS_ORDER` | `"nvim vim vi"` | Terminal editor preference |

### PATH

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_PATH_HOMEBREW` | `true` | Detect and init Homebrew |
| `ZSH_PATH_CLEAN` | `true` | Remove non-existent dirs |
| `ZSH_PATH_PROJECT_BIN` | `false` | Add `./bin`, `./node_modules/.bin` |
| `ZSH_PATH_SSH_MINIMAL` | `true` | Minimal PATH in SSH |
| `ZSH_PATH_FORCE_MINIMAL` | `false` | Force minimal PATH always |

### History

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_HISTORY_SIZE` | `100000` | Commands in memory |
| `ZSH_HISTORY_SAVE_SIZE` | `100000` | Commands saved to file |
| `ZSH_HISTORY_SECURITY_FILTER` | `true` | Filter sensitive commands |

### Completion

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_COMPLETION_TTL` | `86400` | Compdump TTL in seconds (24h) |
| `ZSH_COMPLETION_MENU_SELECT` | `true` | Arrow-key menu selection |

### Aliases

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_ALIASES_MODERN_TOOLS` | `true` | Use eza, bat, ripgrep, etc. |
| `ZSH_ALIASES_SAFETY_PROMPTS` | `true` | Confirm destructive ops |

### Compilation

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_COMPILATION_CLEANUP_ON_START` | `true` | Clean stale .zwc on startup |

### Update Check

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_UPDATE_CHECK_ENABLED` | `true` | Check for updates on shell launch |
| `ZSH_UPDATE_CHECK_INTERVAL` | `86400` | Seconds between checks (24h) |
| `ZSH_UPDATE_AUTO_FETCH` | `true` | Fetch updates in background |

### Other

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_VERIFY_FILE_OWNERSHIP` | `false` | Check file ownership before sourcing |

## Customization

Create `local.zsh` (gitignored) for personal settings:

```bash
cp local.zsh.example local.zsh
$EDITOR local.zsh
```

Example customizations:

```bash
# Directory shortcuts
alias dev='cd ~/Development'
alias prj='cd ~/Projects'

# Enable project-local binaries
export ZSH_PATH_PROJECT_BIN=true

# Override locale
export ZSH_LOCALE_OVERRIDE="en_US.UTF-8"

# Debug mode (see all module loading)
export ZSH_LOG_LEVEL=DEBUG

# Disable lazy loading for specific tools
export ZSH_LAZY_STARSHIP=false
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

| Command | Alias | Description |
|---------|-------|-------------|
| `zsh_lazy_status` | - | Show lazy loading status |
| `zsh_update` | - | Update to latest version |
| `zsh_version` | - | Show current version |
| `path_show` | `path` | Display PATH entries |
| `path_debug` | `pathdebug` | PATH diagnostics |
| `history_stats` | `hstats` | Top commands chart |
| `zsh_alias_browser` | `als` | Interactive alias browser |
| `calc <expr>` | - | Calculator (`calc 2 * 2`) |

## Troubleshooting

**Commands not found after install:**
```bash
exec zsh  # Restart shell completely
```

**Debug module loading:**
```bash
export ZSH_LOG_LEVEL=DEBUG
exec zsh
```

**Check lazy loading status:**
```bash
zsh_lazy_status
```

**PATH issues:**
```bash
pathdebug      # Show diagnostics
pathclean      # Remove non-existent entries
```

**Reset completion cache:**
```bash
rm -f ~/.cache/zsh/completion/zcompdump*
exec zsh
```

## Dependencies

**Required:**
- ZSH 5.8+
- [Oh My Zsh](https://ohmyz.sh/)

**Recommended:**
- [starship](https://starship.rs/) - Cross-shell prompt
- [atuin](https://atuin.sh/) - Shell history sync
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smarter cd
- [eza](https://github.com/eza-community/eza) - Modern ls
- [bat](https://github.com/sharkdp/bat) - Modern cat
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Modern grep

```bash
# macOS
brew install starship atuin fzf zoxide eza bat ripgrep

# Linux (Ubuntu/Debian)
# See individual tool docs for installation
```

## License

MIT
