# Utils Library

Core utility functions used by all modules. All functions use the `_` prefix (internal helpers).

## Overview

The utils library provides foundational functions that other modules depend on:

- Command existence checking
- Environment detection
- File system helpers
- Caching utilities
- Safe file sourcing

## Command Checks

### `_has_cmd <command>`

Check if a command exists in PATH.

```bash
if _has_cmd git; then
    echo "Git is installed"
fi

# Use in conditionals
_has_cmd brew && eval "$(brew shellenv)"
```

**Implementation:** Uses ZSH's `$+commands[]` for fast hash lookup (no subprocess).

### `_require_cmd <command>`

Require a command to exist, log error if missing.

```bash
_require_cmd docker || return 1

# Now safe to use docker
docker ps
```

Returns:
- `0` if command exists
- `1` with ERROR log if missing

## Environment Detection

### `_is_ssh_session`

Check if running in an SSH session.

```bash
if _is_ssh_session; then
    export EDITOR="vim"  # No GUI available
fi
```

Detects via: `SSH_CLIENT`, `SSH_TTY`, `SSH_CONNECTION`

### `_is_docker`

Check if running inside a Docker container.

```bash
if _is_docker; then
    echo "Running in container"
fi
```

Detects via: `/.dockerenv` file or cgroup

### `_is_ci`

Check if running in CI/CD environment.

```bash
if _is_ci; then
    export Z_LOG_LEVEL=NONE  # Quiet mode
fi
```

Detects: GitHub Actions, GitLab CI, Jenkins, Travis

### `_is_interactive`

Check if shell is interactive.

```bash
if _is_interactive; then
    # Only run in interactive shells
    source ~/.config/zsh/modules/keybindings.zsh
fi
```

### `_is_login_shell`

Check if shell is a login shell.

```bash
if _is_login_shell; then
    # Run login-specific setup
fi
```

## File System Helpers

### `_ensure_dir <directory> [permissions]`

Create directory if it doesn't exist.

```bash
_ensure_dir "$HOME/.cache/zsh"
_ensure_dir "$HOME/.local/share/zsh" 700  # With permissions
```

- Creates parent directories (`mkdir -p`)
- Optionally sets permissions
- Logs creation at DEBUG level

### `_ensure_file <file> [permissions]`

Create file if it doesn't exist.

```bash
_ensure_file "$HOME/.zsh_history"
_ensure_file "$HOME/.config/secrets" 600  # Restricted permissions
```

## String Utilities

### `_is_empty <string>`

Check if string is empty.

```bash
if _is_empty "$VAR"; then
    VAR="default"
fi
```

### `_is_not_empty <string>`

Check if string is not empty.

```bash
_is_not_empty "$API_KEY" && use_api
```

## Caching Helpers

### `_cache_eval <name> <command> [binary]`

Cache and source the output of a command.

```bash
_cache_eval "direnv" "direnv hook zsh" "direnv"
_cache_eval "helm-completion" "helm completion zsh" "helm"
```

**Parameters:**
- `name` - Cache file identifier
- `command` - Command to run and cache
- `binary` - Binary to check for updates (defaults to name)

**Cache location:** `$XDG_CACHE_HOME/zsh/<name>.zsh`

**Regeneration triggers:**
1. Cache file doesn't exist
2. Binary is newer than cache file

**Security Warning:**
> ⚠️ Only use with trusted, hardcoded commands. Never pass user input.

## Safe Sourcing

### `_safe_source <file>`

Source a file with optional ownership verification.

```bash
_safe_source "$HOME/.config/zsh/.zshlocal"
```

**Behavior:**
- Returns 1 if file not readable
- Optionally verifies file ownership (see below)

### File Ownership Verification

Enable strict ownership checking:

```bash
export Z_VERIFY_FILE_OWNERSHIP=true
```

When enabled, `_safe_source` will:
- Check file owner matches current user or root
- Skip files owned by other users
- Log warning for untrusted files

**Default:** Disabled (most users don't need this)

## Dependency Checks

### `_require_omz`

Check if Oh My Zsh is installed.

```bash
_require_omz || return 1
```

Shows helpful error with installation instructions if missing.

## Logging Fallback

If the logging module hasn't loaded yet, utils provides a minimal fallback:

```bash
_log() {
    local level="$1"; shift
    if [[ "$level" == "WARN" || "$level" == "ERROR" ]]; then
        print -ru2 -- "[$level] $*"
    fi
}
```

This ensures modules can use `_log` before logging.zsh loads.

## Usage in Modules

Typical module pattern:

```bash
#!/usr/bin/env zsh

# Idempotent guard
(( ${+_MY_MODULE_LOADED} )) && return 0
typeset -g _MY_MODULE_LOADED=1

# Check dependencies
_require_cmd some-tool || return 0

# Environment-aware setup
if _is_ssh_session; then
    # Minimal setup for SSH
    return 0
fi

# Interactive-only setup
_is_interactive || return 0

# Create needed directories
_ensure_dir "$XDG_CACHE_HOME/my-module"

# Your module code...

_log DEBUG "My module loaded"
```

## Function Summary

| Function | Purpose |
|----------|---------|
| `_has_cmd` | Check command exists |
| `_require_cmd` | Require command or error |
| `_is_ssh_session` | Detect SSH |
| `_is_docker` | Detect container |
| `_is_ci` | Detect CI/CD |
| `_is_interactive` | Check interactive shell |
| `_is_login_shell` | Check login shell |
| `_ensure_dir` | Create directory |
| `_ensure_file` | Create file |
| `_is_empty` | Check empty string |
| `_is_not_empty` | Check non-empty string |
| `_cache_eval` | Cache command output |
| `_safe_source` | Source with checks |
| `_require_omz` | Verify Oh My Zsh |
