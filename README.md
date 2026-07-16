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
| **Tool Catalog** | 39-tool catalog with opt-in classic-command replacements (`Z_REPLACE_*`) |
| **Unified Explorers** | One fzf identity for `als`, `help -i`, and XDG conflicts (`ctrl-/` toggles preview) |
| **Performance** | 107ms interactive startup (measured with hyperfine), cached tool init |

## Quick Start

```bash
# Option 1: Clone and install (recommended)
git clone https://github.com/chiptoma/dotfiles-zsh ~/.config/zsh
~/.config/zsh/install.sh

# Option 2: One-liner via curl
curl -fsSL https://raw.githubusercontent.com/chiptoma/dotfiles-zsh/main/install.sh | bash
```

See [INSTALL.md](INSTALL.md) for what the installer does, all flags, and unattended installs.

## Architecture

```
~/.config/zsh/
├── .zshenv                 # Entry point: XDG, core lib, registry, path, environment
├── .zshrc                  # Interactive: modules, plugins, keybindings, .zshlocal
├── .zshlocal               # User customizations (gitignored)
├── modules/                # Numbered by load order: path, environment, lazy,
│                           #   completion, history, aliases, keybindings
├── lib/
│   ├── core/               # Logging, UI, helpers, profiler, platform detection
│   ├── functions/          # User-facing z_* commands (auto-discovered)
│   ├── plugins/            # Plugin loader + vendored widgets
│   └── registry/           # Tool knowledge: paths, env vars, tools.dat catalog
├── tools/                  # Shipped tool configs (manifest-driven)
├── completions/            # Custom + installer-generated completions
├── ansible/                # Ansible role + playbook for fleet installs
├── tests/                  # Test suites (see docs/TESTING.md)
└── Justfile                # Task runner — single entry for dev tasks
```

## Performance

Interactive startup is measured with hyperfine (`just bench`):

| Configuration | Mean startup |
|---------------|--------------|
| Previous (Oh My Zsh based) | 173ms |
| Current (self-managed plugins) | **107ms** |

Contributing factors: no framework overhead, cached `eval` of tool init (starship, atuin, zoxide, fzf, mise), lazy loading of version managers, and a compiled completion dump.

```bash
Z_PROFILE_STARTUP=true zsh -ic z_profile   # Per-stage timing breakdown
Z_PROFILE_STARTUP=zprof zsh -ic exit       # Function-level (zprof) report
```

## Documentation

### Guides

| Guide | Description |
|-------|-------------|
| [INSTALL.md](INSTALL.md) | Installation flags, profiles, unattended installs |
| [docs/COMMANDS.md](docs/COMMANDS.md) | Full command reference (generated via `just docs-commands`) |
| [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) | Personalizing via `.zshlocal`, command replacements |
| [docs/TESTING.md](docs/TESTING.md) | Test layers and the `just` workflow |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Debugging guide |

### Module Reference

| Module | Docs | Description |
|--------|------|-------------|
| Core | [docs/reference/core.md](docs/reference/core.md) | Core helpers: `_has_cmd`, `_safe_source`, `_cache_eval` |
| Logging | [docs/reference/logging.md](docs/reference/logging.md) | `_log` with levels, colors, caller info |
| Platform | [docs/reference/platform.md](docs/reference/platform.md) | macOS/Linux detection and helpers |
| PATH | [docs/reference/path.md](docs/reference/path.md) | PATH management, dev tools, version managers |
| Environment | [docs/reference/environment.md](docs/reference/environment.md) | XDG compliance, editor detection, SSH agent |
| Lazy Loading | [docs/reference/lazy.md](docs/reference/lazy.md) | Deferred init for fast startup |
| Completion | [docs/reference/completion.md](docs/reference/completion.md) | Tab completion with caching |
| History | [docs/reference/history.md](docs/reference/history.md) | Security filtering, search, statistics |
| Aliases | [docs/reference/aliases.md](docs/reference/aliases.md) | 75+ aliases, modern tool replacements |
| Keybindings | [docs/reference/keybindings.md](docs/reference/keybindings.md) | Atuin, navigation, editing shortcuts |
| Functions | [docs/reference/functions.md](docs/reference/functions.md) | 30+ utility functions (calc, weather, ports, etc.) |

## Configuration

Every tunable lives in [examples/zshlocal](examples/zshlocal) — the master control panel, grouped by module and commented with defaults. Copy it to `.zshlocal`, uncomment what you need, and see [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for aliases, functions, plugins, and command replacements.

## Customization

Create `.zshlocal` (gitignored, survives updates) for personal settings:

```bash
cp examples/zshlocal .zshlocal
$EDITOR .zshlocal
```

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for the full guide.

## Plugins

Plugins are plain git clones in `~/.local/share/zsh/plugins`, installed by the installer and loaded by `lib/plugins/index.zsh` — no plugin manager required:

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — inline history suggestions
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) — command colorization (loads last, from `.zshrc`)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab) — fzf-powered completion menu (loads right after `compinit`)

Small widgets (`dirhistory`, `sudo`) are vendored in `lib/plugins/vendor/`.

## Key Bindings

Atuin history on `Up/Down` and `Ctrl-R`, directory history on `Alt-Up/Down`, plus word-wise editing shortcuts. Full map in [docs/reference/keybindings.md](docs/reference/keybindings.md).

## Useful Commands

The full command reference lives in [docs/COMMANDS.md](docs/COMMANDS.md), or run `help` in the shell (`help -i` for the interactive explorer). Highlights: `lazy` (loading status), `zupdate`, `als` (alias browser), `sshagent`, `health`, `profile`.

## Development

All dev, test, and maintenance tasks run through the [Justfile](Justfile) — run `just` to list recipes, `just test` for the safe local suite. See [docs/TESTING.md](docs/TESTING.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## Troubleshooting

First aid: `exec zsh` (restart), `export Z_LOG_LEVEL=DEBUG` (verbose loading), `install.sh --check` (health). Full guide: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

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

The full 39-tool catalog lives in `lib/registry/tools.dat` (see [INSTALL.md](INSTALL.md) for the tier list).

```bash
# macOS
brew install starship atuin fzf zoxide eza bat ripgrep fd

# Linux (Ubuntu/Debian) - see INSTALL.md for details
# Note: bat→batcat, fd→fdfind on Debian-based systems
```

## License

MIT
