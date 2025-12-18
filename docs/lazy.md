# Lazy Loading Module

Defers expensive tool initialization until first use, significantly reducing shell startup time.

## Why Lazy Loading?

Some tools have slow initialization:

| Tool | Typical Init Time | What It Does |
|------|-------------------|--------------|
| starship | ~50-100ms | Evaluate `starship init zsh` |
| atuin | ~30-50ms | Evaluate `atuin init zsh` |
| nvm | ~200-400ms | Source nvm.sh, set up completions |
| pyenv | ~100-200ms | Evaluate `pyenv init -` |
| rbenv | ~50-100ms | Evaluate `rbenv init -` |

With lazy loading, these tools only initialize when you first use them, shaving **hundreds of milliseconds** off shell startup.

## How It Works

1. **Wrapper Creation** - Instead of running `eval "$(starship init zsh)"` at startup, a lightweight wrapper function is created
2. **First Use Detection** - When you first run the command (or need the prompt), the wrapper triggers real initialization
3. **Transparent Replacement** - The wrapper removes itself and calls the real command
4. **No Repeated Cost** - Subsequent uses are full speed

```
Before lazy loading:
  shell start → init starship → init atuin → init nvm → ready (600ms)

After lazy loading:
  shell start → ready (50ms)
  first prompt → init starship (100ms)
  first `node` → init nvm (200ms)
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_LAZY_ENABLED` | `true` | Enable/disable lazy loading |
| `Z_LAZY_STARSHIP` | `true` | Lazy load starship prompt |
| `Z_LAZY_ATUIN` | `true` | Lazy load atuin history |
| `Z_LAZY_ZOXIDE` | `true` | Lazy load zoxide |
| `Z_LAZY_NVM` | `true` | Lazy load nvm |
| `Z_LAZY_PYENV` | `true` | Lazy load pyenv |
| `Z_LAZY_RBENV` | `true` | Lazy load rbenv |

## Disable for Specific Tools

If you need immediate initialization for a specific tool:

```bash
# In .zshlocal
export Z_LAZY_NVM=false     # Initialize nvm immediately
export Z_LAZY_STARSHIP=false  # Initialize starship immediately
```

## Check Status

Use `z_lazy_status` to see which tools are configured and initialized:

```bash
$ z_lazy_status

Lazy Loading Status:
====================

Configuration:
  Z_LAZY_ENABLED:   true
  Z_LAZY_STARSHIP:  true
  Z_LAZY_ATUIN:     true
  Z_LAZY_ZOXIDE:    true
  Z_LAZY_NVM:       true
  Z_LAZY_PYENV:     true
  Z_LAZY_RBENV:     true

Initialized Tools:
  ✓ starship
  ✓ zoxide
  (none yet - tools initialize on first use)
```

## Supported Tools

### Starship (Prompt)

- **Trigger:** First prompt display
- **Method:** precmd hook
- **Commands wrapped:** None (prompt-only)

### Atuin (History)

- **Trigger:** Using `atuin` command or Ctrl-R
- **Method:** Function wrapper
- **Commands wrapped:** `atuin`

### Zoxide (Directory Jumping)

- **Trigger:** Using `z` or `zi`
- **Method:** Function wrapper
- **Commands wrapped:** `z`, `zi`

### NVM (Node Version Manager)

- **Trigger:** Using `nvm`, `node`, `npm`, `npx`, `yarn`, or `pnpm`
- **Method:** Function wrapper
- **Commands wrapped:** `nvm`, `node`, `npm`, `npx`, `yarn`, `pnpm`

### Pyenv (Python Version Manager)

- **Trigger:** Using `pyenv`, `python`, `python3`, `pip`, or `pip3`
- **Method:** Function wrapper
- **Commands wrapped:** `pyenv`, `python`, `python3`, `pip`, `pip3`

### Rbenv (Ruby Version Manager)

- **Trigger:** Using `rbenv`, `ruby`, `gem`, or `bundle`
- **Method:** Function wrapper
- **Commands wrapped:** `rbenv`, `ruby`, `gem`, `bundle`

## Custom Lazy Loading

You can register your own commands for lazy loading:

```bash
# In .zshlocal

# Simple command wrapping
lazy_load "mycmd" "eval \"\$(mycmd init zsh)\""

# With aliases that also trigger init
lazy_load "mycmd" "eval \"\$(mycmd init zsh)\"" "mc" "mycmd-alias"
```

## Troubleshooting

### Tool not initializing

Check if the base command exists:

```bash
command -v starship  # Should show path
command -v nvm       # May not exist until sourced
```

### Debug initialization

```bash
export Z_LOG_LEVEL=DEBUG
exec zsh
# Now trigger the tool - you'll see "Lazy initializing: <tool>"
```

### Force immediate initialization

```bash
# Disable lazy loading entirely
export Z_LAZY_ENABLED=false
exec zsh
```

### Check if tool was lazily loaded

```bash
z_lazy_status | grep "Initialized"
```
