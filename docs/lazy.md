# Lazy Loading Module

Defers expensive tool initialization until first use, reducing shell startup time.

## Why Lazy Loading?

Some tools have slow initialization:

| Tool | Typical Init Time | What It Does |
|------|-------------------|--------------|
| nvm | ~200-400ms | Source nvm.sh, set up completions |
| pyenv | ~100-200ms | Evaluate `pyenv init -` |
| rbenv | ~50-100ms | Evaluate `rbenv init -` |
| zoxide | ~10-30ms | Evaluate `zoxide init zsh` |

With lazy loading, these tools only initialize when you first use them, shaving **hundreds of milliseconds** off shell startup. Fast-init tools (starship, atuin, fzf) are handled differently — their init output is cached to disk by `_cache_eval` in the environment module, so they cost almost nothing at startup and don't need deferral.

## How It Works

The module defines one `_lazy_init_<tool>` function per supported tool (`modules/03_lazy.zsh`):

1. **Wrapper Creation** - Instead of running the tool's init at startup, lightweight wrapper functions are created for its commands
2. **First Use Detection** - When you first run any wrapped command, the wrapper triggers real initialization
3. **Transparent Replacement** - The wrapper unfunctions itself and re-invokes the real command
4. **No Repeated Cost** - Subsequent uses are full speed; init output is cached via `_cache_eval` where possible

```
Before lazy loading:
  shell start → init nvm → init pyenv → init rbenv → ready

After lazy loading:
  shell start → ready
  first `node` → init nvm (once)
  first `python` → init pyenv (once)
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_LAZY_ENABLED` | `true` | Enable/disable lazy loading |
| `Z_LAZY_ZOXIDE` | `true` | Lazy load zoxide |
| `Z_LAZY_NVM` | `true` | Lazy load nvm |
| `Z_LAZY_PYENV` | `true` | Lazy load pyenv |
| `Z_LAZY_RBENV` | `true` | Lazy load rbenv |

## Disable for Specific Tools

If you need immediate initialization for a specific tool:

```bash
# In .zshlocal
export Z_LAZY_NVM=false     # Skip nvm wrappers entirely
export Z_LAZY_ZOXIDE=false  # Initialize zoxide immediately (cached)
```

Note: setting `Z_LAZY_ZOXIDE=false` initializes zoxide eagerly at startup; setting `Z_LAZY_NVM`/`Z_LAZY_PYENV`/`Z_LAZY_RBENV` to `false` skips their wrappers — initialize those managers yourself in `.zshlocal` if you need them eagerly.

## Check Status

Use `z_lazy_status` (alias: `lazy`) to see the configuration and which tools have initialized:

```bash
$ z_lazy_status

Lazy Loading Status

Configuration
  Z_LAZY_ENABLED  true
  Z_LAZY_ZOXIDE   true
  Z_LAZY_NVM      true
  Z_LAZY_PYENV    true
  Z_LAZY_RBENV    true

Loaded Tools
  (none yet - tools initialize on first use)
```

## Supported Tools

### Zoxide (Directory Jumping)

- **Trigger:** Using `z` or `zi`
- **Method:** Function wrapper (`_lazy_init_zoxide`), cached init
- **Commands wrapped:** `z`, `zi`

### NVM (Node Version Manager)

- **Trigger:** Using `nvm`, `node`, `npm`, `npx`, `yarn`, or `pnpm`
- **Method:** Function wrapper (`_lazy_init_nvm`); only registers when `$NVM_DIR` (or `~/.nvm`) exists
- **Commands wrapped:** `nvm`, `node`, `npm`, `npx`, `yarn`, `pnpm`

### Pyenv (Python Version Manager)

- **Trigger:** Using `pyenv`, `python`, `python3`, `pip`, or `pip3`
- **Method:** Function wrapper (`_lazy_init_pyenv`), cached init; only registers when `$PYENV_ROOT` (or `~/.pyenv`) exists
- **Commands wrapped:** `pyenv`, `python`, `python3`, `pip`, `pip3`

### Rbenv (Ruby Version Manager)

- **Trigger:** Using `rbenv`, `ruby`, `gem`, or `bundle`
- **Method:** Function wrapper (`_lazy_init_rbenv`), cached init
- **Commands wrapped:** `rbenv`, `ruby`, `gem`, `bundle`

## What About Starship, Atuin, fzf?

They are **not** lazy loaded — they are cheap because their init scripts are cached:

- **starship** initializes via a post-interactive hook (`_env_init_starship`), after `/etc/zshrc`, with `_cache_eval`
- **atuin** initializes in the environment module (interactive shells only, cached) so its ZLE widgets exist before keybindings load
- **fzf** shell bindings and **1Password CLI** completion are cached in the plugin loader

## Troubleshooting

### Tool not initializing

Check if the base command or install directory exists:

```bash
command -v zoxide    # Should show path
ls ~/.nvm            # nvm wrappers only register when this exists
```

### Debug initialization

```bash
export Z_LOG_LEVEL=DEBUG
exec zsh
# Now trigger the tool - you'll see "<tool> initialized (lazy)"
```

### Disable the module entirely

```bash
export Z_LAZY_ENABLED=false
exec zsh
```

With the module off, no wrappers are registered and nothing is initialized for you — source your version managers yourself in `.zshlocal` if you still need them.

### Check if tool was lazily loaded

```bash
z_lazy_status
```
