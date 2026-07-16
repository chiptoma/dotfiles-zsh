# Completion Module

Smart, fast, and user-friendly tab completion system with caching and intelligent matching.

## Features

### Performance Optimized

- **Smart Caching** - Completion cache with configurable TTL (default: 24 hours)
- **Lazy Regeneration** - Only regenerates compdump when needed
- **Compiled Cache** - Automatically compiles compdump to `.zwc` for faster loading
- **Auto-Rehash** - Finds new commands without shell restart

### Smart Matching

- **Case-Smart** - Lowercase matches any case, uppercase matches exactly
- **Fuzzy Matching** - Tolerates typos with approximate completions
- **Partial Completion** - Complete from middle of filenames
- **Hidden Files** - Shows dotfiles in completion results
- **Directory First** - Prioritizes directories in file listings

### Enhanced User Experience

- **Menu Selection** - Navigate completions with arrow keys
- **Grouped Results** - Completions organized by type with descriptions
- **Colorized Output** - Matches your `LS_COLORS`
- **Kill Signals** - Shows signal names when completing `kill`
- **Smart cd** - Won't suggest parent directory when already there

### Tool Integration

- **fzf-tab Ready** - Runs `compinit` before the plugin loader so fzf-tab can take over the menu
- **Bash Compat** - Loads `bashcompinit` for AWS CLI and similar tools
- **Homebrew** - Auto-detects Homebrew completion paths
- **Helm Support** - Kubernetes package manager completions (cached)

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_COMPLETION_ENABLED` | `true` | Enable/disable completion module |
| `Z_COMPLETION_TTL` | `86400` | Compdump TTL in seconds (24 hours) |
| `Z_COMPLETION_MENU_SELECT` | `true` | Enable arrow-key menu selection |

## Custom Completions

The installer generates completion files for installed catalog tools that can emit their own (catalog column 8 in `lib/registry/tools.dat`), writing them to `$ZDOTDIR/completions/_<binary>` and resetting the compdump so the next shell picks them up. Package-managed tools (brew/apt) ship completions via site-functions instead.

Add your own custom completion files to these directories (checked in order):

1. `~/.config/zsh/completions` (highest priority)
2. `$ZDOTDIR/completions`
3. `$XDG_DATA_HOME/zsh/completions`
4. Legacy Oh My Zsh completion dirs (only if `$ZSH` is set by an old install)
5. `/opt/homebrew/share/zsh/site-functions` (Homebrew on Apple Silicon)
6. `/usr/local/share/zsh/site-functions` (Homebrew on Intel)

## Shell Options

The module enables these ZSH options:

| Option | Effect |
|--------|--------|
| `ALWAYS_TO_END` | Move cursor to end after completion |
| `AUTO_MENU` | Show menu on tab press |
| `COMPLETE_IN_WORD` | Complete from cursor position |
| `NO_MENU_COMPLETE` | Don't autoselect first item |
| `NO_LIST_BEEP` | No beep on ambiguous completion |

`COMPLETE_ALIASES` is deliberately **not** set: unset, zsh expands an alias before completing, so aliases inherit the completions of the command they expand to (`gcleanup <TAB>` gets `z_git_cleanup`'s completions, git aliases get git's). Set, every alias would need its own `compdef` and gets none.

## Completion Styles

### Matching

```zsh
# Case-smart matching: lowercase matches anything, uppercase is exact
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' ...

# Fuzzy matching with increasing tolerance
zstyle ':completion:*' matcher-list '' \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'
```

### Formatting

```zsh
# Grouped results with colored headers
zstyle ':completion:*:descriptions' format '%B%F{yellow}── %d ──%f%b'
zstyle ':completion:*:warnings'     format '%B%F{red}── no matches found ──%f%b'
```

### Performance

```zsh
# Cache expensive completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_HOME/completion"

# Accept exact matches immediately
zstyle ':completion:*' accept-exact '*(N)'
```

## File Locations

| Purpose | Path |
|---------|------|
| Compdump | `$ZSH_CACHE_HOME/completion/zcompdump-$ZSH_VERSION` |
| Cache | `$ZSH_CACHE_HOME/completion/` |

## Troubleshooting

### Reset Completion Cache

```bash
rm -f ~/.cache/zsh/completion/zcompdump*
exec zsh
```

### Rebuild Completions

```bash
autoload -U compinit && compinit
```

### Debug Completion

```bash
# See what completers are being used
zstyle -L ':completion:*'

# Trace completion for a specific command
_complete_debug
```

### Check fpath

```bash
echo $fpath | tr ' ' '\n'
```

## Dependencies

- **Required:** None (uses built-in ZSH completion)
- **Optional:** `helm` for Kubernetes completions

## Notes

- Loads **before** the plugin loader (`lib/plugins/index.zsh`) so `compinit` has run by the time fzf-tab needs it
- Only adds directories to fpath if they exist
