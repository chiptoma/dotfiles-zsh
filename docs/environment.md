# Environment Module

Comprehensive environment variable management with XDG compliance and automatic tool detection.

## Features

### XDG Compliance

Enforces XDG Base Directory Specification for 50+ tools, keeping your home directory clean:

```
~/.config/       # XDG_CONFIG_HOME - Configuration files
~/.cache/        # XDG_CACHE_HOME  - Non-essential cached data
~/.local/share/  # XDG_DATA_HOME   - Application data
~/.local/state/  # XDG_STATE_HOME  - State data (logs, history)
```

### Automatic Editor Detection

Finds and configures your preferred editor:

1. Checks GUI editors in order: `surf`, `cursor`, `code`
2. Falls back to terminal editors: `nvim`, `vim`, `vi`
3. Sets `EDITOR`, `VISUAL`, and `TERMINAL_EDITOR` appropriately

### SSH Agent Integration

Automatically detects and configures SSH agent socket:

- 1Password SSH agent
- macOS Keychain
- Standard ssh-agent
- GPG agent

### Tool-Specific XDG Paths

Configures XDG-compliant paths for:

| Category | Tools |
|----------|-------|
| **JavaScript** | Volta, npm, yarn, pnpm, Node REPL, NVM, Bun |
| **Go** | GOPATH, GOCACHE, GOMODCACHE |
| **Python** | pip, Poetry, pyenv, virtualenv, IPython, Jupyter, Ruff |
| **Ruby** | gem, bundle, rbenv, Solargraph |
| **Rust** | Cargo, rustup |
| **Docker** | Docker config, Compose |
| **Kubernetes** | kubectl, Helm, k9s, krew, kubectx |
| **JVM** | SDKMAN, Maven, Gradle, SBT |
| **Cloud** | AWS, GCP, Azure |
| **Databases** | MySQL, PostgreSQL, Redis, SQLite |
| **Security** | GPG, password-store, age |
| **General** | wget, less, ripgrep, fzf, Starship |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_ENVIRONMENT_ENABLED` | `true` | Enable/disable environment module |
| `Z_ENVIRONMENT_XDG_STRICT` | `true` | Enforce XDG for all tools |
| `Z_ENVIRONMENT_SSH_MINIMAL` | `true` | Minimal env in SSH sessions |
| `Z_ENVIRONMENT_SSH_AGENT` | `true` | Auto-detect SSH agent socket |
| `Z_LOCALE_OVERRIDE` | empty | Override system locale |
| `Z_GUI_EDITORS_ORDER` | `"surf cursor code"` | GUI editor preference order |
| `Z_TERMINAL_EDITORS_ORDER` | `"nvim vim vi"` | Terminal editor preference |

## XDG Directory Structure

After using this configuration, tool data is organized:

```
~/.config/
├── zsh/           # ZSH configuration
├── git/           # Git config
├── npm/           # npm config
├── yarn/          # Yarn config
├── pip/           # pip config
├── docker/        # Docker config
├── kubectl/       # kubectl config
└── ...

~/.cache/
├── zsh/           # ZSH cache (completion, etc.)
├── npm/           # npm cache
├── go/            # Go build cache
├── pip/           # pip cache
└── ...

~/.local/share/
├── zsh/           # ZSH data
├── volta/         # Volta (Node version manager)
├── go/            # GOPATH
├── nvm/           # NVM
└── ...

~/.local/state/
├── zsh/           # ZSH state (history)
├── node_repl_history
├── python_history
└── ...
```

## Editor Configuration

### Automatic Detection

The module automatically finds editors by checking:

```bash
# GUI editors (in order)
Z_GUI_EDITORS_ORDER="surf cursor code"

# Terminal editors (in order)
Z_TERMINAL_EDITORS_ORDER="nvim vim vi"
```

### Environment Variables Set

| Variable | Purpose |
|----------|---------|
| `EDITOR` | Default editor (terminal-friendly) |
| `VISUAL` | Visual editor (may be GUI) |
| `TERMINAL_EDITOR` | Always terminal-based |
| `GIT_EDITOR` | Git commit editor |
| `KUBE_EDITOR` | Kubernetes resource editor |

### Custom Editor Order

```bash
# In .zshlocal
export Z_GUI_EDITORS_ORDER="code cursor sublime"
export Z_TERMINAL_EDITORS_ORDER="vim nano"
```

## SSH Agent Detection

Order of preference:

1. **1Password** - `~/Library/Group Containers/.../agent.sock`
2. **macOS Keychain** - `launchd` socket
3. **Standard Agent** - `$SSH_AUTH_SOCK`
4. **GPG Agent** - `gpgconf --list-dirs agent-ssh-socket`

Disable with:
```bash
export Z_ENVIRONMENT_SSH_AGENT=false
```

## Locale Configuration

Override system locale:

```bash
# In .zshlocal
export Z_LOCALE_OVERRIDE="en_US.UTF-8"
```

This sets `LANG`, `LC_ALL`, and `LANGUAGE`.

## SSH Session Detection

In SSH sessions (when `Z_ENVIRONMENT_SSH_MINIMAL=true`):

- Skips GUI editor detection
- Reduces environment setup
- Faster shell startup

## Hooks

The module provides hooks for customization:

```bash
# Run before environment setup
Z_PRE_ENV_INIT_HOOKS+=('my_pre_init_function')

# Run after environment setup
Z_POST_ENV_INIT_HOOKS+=('my_post_init_function')
```

## Tool-Specific Variables

### JavaScript

| Variable | Value |
|----------|-------|
| `VOLTA_HOME` | `$XDG_DATA_HOME/volta` |
| `NPM_CONFIG_USERCONFIG` | `$XDG_CONFIG_HOME/npm/npmrc` |
| `NPM_CONFIG_CACHE` | `$XDG_CACHE_HOME/npm` |
| `YARN_CACHE_FOLDER` | `$XDG_CACHE_HOME/yarn` |
| `PNPM_HOME` | `$XDG_DATA_HOME/pnpm` |
| `NODE_REPL_HISTORY` | `$XDG_STATE_HOME/node_repl_history` |
| `NVM_DIR` | `$XDG_DATA_HOME/nvm` |
| `BUN_INSTALL` | `$XDG_DATA_HOME/bun` |

### Go

| Variable | Value |
|----------|-------|
| `GOPATH` | `$XDG_DATA_HOME/go` |
| `GOCACHE` | `$XDG_CACHE_HOME/go` |
| `GOMODCACHE` | `$XDG_CACHE_HOME/go-mod` |

### Python

| Variable | Value |
|----------|-------|
| `PYTHONSTARTUP` | `$XDG_CONFIG_HOME/python/pythonrc` |
| `PYTHON_HISTORY` | `$XDG_STATE_HOME/python_history` |
| `PIP_CONFIG_FILE` | `$XDG_CONFIG_HOME/pip/pip.conf` |
| `PIP_CACHE_DIR` | `$XDG_CACHE_HOME/pip` |
| `POETRY_HOME` | `$XDG_DATA_HOME/poetry` |
| `PYENV_ROOT` | `$XDG_DATA_HOME/pyenv` |
| `IPYTHONDIR` | `$XDG_CONFIG_HOME/ipython` |
| `JUPYTER_CONFIG_DIR` | `$XDG_CONFIG_HOME/jupyter` |

### Docker & Kubernetes

| Variable | Value |
|----------|-------|
| `DOCKER_CONFIG` | `$XDG_CONFIG_HOME/docker` |
| `KUBECONFIG` | `$XDG_CONFIG_HOME/kube/config` |
| `KUBECACHEDIR` | `$XDG_CACHE_HOME/kube` |
| `HELM_CONFIG_HOME` | `$XDG_CONFIG_HOME/helm` |
| `HELM_CACHE_HOME` | `$XDG_CACHE_HOME/helm` |
| `HELM_DATA_HOME` | `$XDG_DATA_HOME/helm` |

## Troubleshooting

### Check Current Editor

```bash
echo "EDITOR=$EDITOR"
echo "VISUAL=$VISUAL"
echo "TERMINAL_EDITOR=$TERMINAL_EDITOR"
```

### Verify XDG Paths

```bash
echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
echo "XDG_CACHE_HOME=$XDG_CACHE_HOME"
echo "XDG_DATA_HOME=$XDG_DATA_HOME"
echo "XDG_STATE_HOME=$XDG_STATE_HOME"
```

### Check SSH Agent

```bash
echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
ssh-add -l  # List loaded keys
```

### Debug Environment Loading

```bash
export Z_LOG_LEVEL=DEBUG
exec zsh
```
