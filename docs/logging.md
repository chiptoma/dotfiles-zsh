# Logging Module

Centralized logging facility with level-based filtering, colors, and caller information.

## Overview

The logging module provides a consistent way to output debug, info, warning, and error messages throughout the ZSH configuration. Messages are automatically filtered based on the configured log level.

## Quick Start

```bash
# In any module or .zshlocal
_log DEBUG "This is a debug message"
_log INFO "Operation completed"
_log WARN "Something might be wrong"
_log ERROR "Something failed"
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_LOG_LEVEL` | `WARN` | Minimum level to display |
| `Z_LOG_COLOR` | `auto` | Color output: `auto`, `true`, `false` |
| `Z_LOG_TIMESTAMP_ENABLE` | `true` | Show timestamps |
| `Z_LOG_TIMESTAMP_FORMAT` | `+%Y-%m-%d %H:%M:%S` | Timestamp format |
| `Z_LOG_SHOW_CALLER` | `true` | Show file:function:line |
| `Z_LOG_SHOW_PID` | `false` | Show process ID |
| `Z_LOG_SHOW_SHELL` | `false` | Show shell context (interactive/login) |

## Log Levels

| Level | Value | Color | Description |
|-------|-------|-------|-------------|
| `DEBUG` | 0 | Grey | Detailed debugging information |
| `INFO` | 1 | Green | General informational messages |
| `WARN` | 2 | Yellow | Warning conditions |
| `ERROR` | 3 | Red | Error conditions |
| `NONE` | 4 | - | Suppress all output |

Messages are only displayed if their level ≥ configured level.

## Usage Examples

### Basic Logging

```bash
_log DEBUG "Checking if starship is installed..."
_log INFO "Starship initialized successfully"
_log WARN "Starship not found, using default prompt"
_log ERROR "Failed to initialize prompt"
```

### Enable Debug Mode

In `.zshlocal` or before starting shell:

```bash
export Z_LOG_LEVEL=DEBUG
```

Then restart:

```bash
exec zsh
```

You'll see detailed output from all modules.

### Runtime Level Change

```bash
# Change level without restart
log_level_set DEBUG

# Do some operations, see all output
source ~/.config/zsh/modules/lazy.zsh

# Restore normal level
log_level_set WARN
```

### Temporary Level Change

```bash
# Run command with different log level
with_log_level DEBUG source ~/.config/zsh/modules/aliases.zsh

# Level automatically restored after
```

## Output Format

Default format with all options enabled:

```
[2024-01-15 14:30:45] [INFO] [aliases.zsh:setup_aliases:42]: Modern tool aliases configured
```

Components:
- `[2024-01-15 14:30:45]` - Timestamp
- `[INFO]` - Log level (colored in terminals)
- `[aliases.zsh:setup_aliases:42]` - File:function:line
- `: Modern tool aliases configured` - Message

### Minimal Format

```bash
export Z_LOG_TIMESTAMP_ENABLE=false
export Z_LOG_SHOW_CALLER=false
```

Output: `[INFO]: Modern tool aliases configured`

### With PID and Shell Context

```bash
export Z_LOG_SHOW_PID=true
export Z_LOG_SHOW_SHELL=true
```

Output: `[INFO] [lazy.zsh:init:15] [pid:12345] [sh:il]: Starship loaded`

Shell context codes:
- `il` = interactive login shell
- `i-` = interactive non-login shell
- `-l` = non-interactive login shell
- `--` = non-interactive non-login shell

## Functions

### `_log <level> <message>`

Main logging function.

```bash
_log INFO "Processing complete"
_log WARN "Disk space low"
```

### `log_level_set <level>`

Change log level at runtime.

```bash
log_level_set DEBUG    # Show everything
log_level_set WARN     # Only warnings and errors
log_level_set NONE     # Silence all output
```

### `with_log_level <level> <command>`

Run command with temporary log level.

```bash
with_log_level DEBUG source some-script.zsh
with_log_level NONE noisy_command
```

## Color Support

Colors are automatically detected:

| Condition | Colors |
|-----------|--------|
| `Z_LOG_COLOR=true` | Always on |
| `Z_LOG_COLOR=false` | Always off |
| `Z_LOG_COLOR=auto` | On if terminal, respects `NO_COLOR` |

Level colors:
- DEBUG: Grey (`\e[90m`)
- INFO: Green (`\e[32m`)
- WARN: Yellow (`\e[33m`)
- ERROR: Red (`\e[31m`)

## Output Routing

- `DEBUG` and `INFO` → stdout
- `WARN` and `ERROR` → stderr

This allows filtering:

```bash
# Only see errors
exec zsh 2>&1 | grep ERROR

# Suppress all output
exec zsh >/dev/null 2>&1
```

## Performance

The logging module uses:
- `zsh/datetime` module for efficient timestamps (no subprocess)
- Early level filtering (message not assembled if filtered)
- No external commands

## Troubleshooting

**No log output at all:**

Check `Z_LOG_LEVEL`:

```bash
echo $Z_LOG_LEVEL
# Should be DEBUG, INFO, WARN, or ERROR (not NONE)
```

**Missing colors:**

```bash
echo $Z_LOG_COLOR
# Try: export Z_LOG_COLOR=true
```

**Caller info shows "unknown":**

This happens when `_log` is called from unusual contexts (eval, process substitution). Normal module usage shows correct caller info.

## Integration

### In Custom Modules

```bash
#!/usr/bin/env zsh

# Guard against re-sourcing
(( ${+_MY_MODULE_LOADED} )) && return 0
typeset -g _MY_MODULE_LOADED=1

_log DEBUG "My module loading..."

# Your code here

_log DEBUG "My module loaded"
```

### In Functions

```bash
my_function() {
    _log DEBUG "my_function called with: $*"

    if [[ -z "$1" ]]; then
        _log ERROR "my_function: argument required"
        return 1
    }

    # Do work
    _log INFO "my_function completed"
}
```

## Best Practices

1. **Use DEBUG** for detailed tracing during development
2. **Use INFO** for significant events (tool initialization, completions)
3. **Use WARN** for recoverable issues (missing optional tool)
4. **Use ERROR** for failures that affect functionality
5. **Default to WARN** in production for clean shell startup

## UI Output Functions

The logging module also provides UI helper functions for user-facing output:

| Function | Description | Visual |
|----------|-------------|--------|
| `_ui_ok` | Success message | ✓ (green checkmark) |
| `_ui_warn` | Warning message | ⚠ (yellow warning) |
| `_ui_error` | Error message | ✗ (red X) |
| `_ui_info` | Informational | (no emoji) |
| `_ui_header` | Section header | Decorated title |
| `_ui_section` | Subsection | Bullet point |
| `_ui_kv` | Key-value pair | Aligned output |

These functions use emoji indicators for visual feedback in interactive shells. The emoji usage is intentional for quick visual scanning of health checks and status output.
