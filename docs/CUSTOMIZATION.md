# Customization Guide

This guide covers how to extend and customize your ZSH configuration without modifying core files.

## The Golden Rule

**Never edit `.zshrc` or `.zshenv` directly.** All customizations go in `.zshlocal`:

```bash
~/.config/zsh/.zshlocal
```

This file is gitignored and survives updates. If it doesn't exist, create it.

## Quick Reference

| Task | Location | Survives Updates |
|------|----------|------------------|
| Add aliases | `.zshlocal` | Yes |
| Add functions | `.zshlocal` | Yes |
| Add plugins | `.zshlocal` | Yes |
| Disable modules | `.zshlocal` | Yes |
| Change PATH | `.zshlocal` | Yes |
| Set environment vars | `.zshlocal` | Yes |

## Adding Aliases

Add aliases directly to `.zshlocal`:

```bash
# ~/.config/zsh/.zshlocal

# Project shortcuts
alias myproj='cd ~/Development/my-project'
alias serve='python -m http.server 8000'

# Tool overrides
alias vim='nvim'
alias cat='bat --style=plain'

# Git shortcuts
alias gp='git push'
alias gl='git pull'
```

To verify your alias was added:

```bash
als | grep myproj    # Search aliases interactively
alias myproj         # Check specific alias
```

## Adding Functions

Define functions directly in `.zshlocal`:

```bash
# ~/.config/zsh/.zshlocal

# Quick project navigation
proj() {
    cd ~/Development/"$1" || return 1
}

# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Quick note
note() {
    echo "$(date '+%Y-%m-%d %H:%M'): $*" >> ~/notes.txt
}
```

For larger functions, create a separate file and source it:

```bash
# ~/.config/zsh/.zshlocal
source ~/my-functions.zsh
```

## Adding Oh My Zsh Plugins

### Built-in Plugins

OMZ includes 300+ plugins. To enable one, add to `.zshlocal`:

```bash
# ~/.config/zsh/.zshlocal

# Load additional OMZ plugins
# Note: Some plugins are already enabled in .zshrc
source "$ZSH/plugins/docker/docker.plugin.zsh"
source "$ZSH/plugins/kubectl/kubectl.plugin.zsh"
source "$ZSH/plugins/npm/npm.plugin.zsh"
```

Browse available plugins:

```bash
ls "$ZSH/plugins"
```

### External Plugins

Clone to `~/.config/zsh/custom/plugins/` and source:

```bash
# Clone the plugin
git clone https://github.com/author/my-plugin ~/.config/zsh/custom/plugins/my-plugin

# Add to .zshlocal
source "$ZDOTDIR/custom/plugins/my-plugin/my-plugin.plugin.zsh"
```

## Disabling Modules

Every module respects an `_ENABLED` flag. Set these **before** `.zshrc` loads:

```bash
# ~/.zshenv (for environment-level changes)
# OR ~/.config/zsh/.zshlocal (for most cases)

# Disable specific modules
export Z_COMPILATION_ENABLED=false    # Disable .zwc compilation
export Z_ALIASES_ENABLED=false        # Disable all aliases
export Z_LAZY_ENABLED=false           # Disable lazy loading
export Z_KEYBINDINGS_ENABLED=false    # Use default keybindings

# Disable specific lazy loaders
export Z_LAZY_NVM=false               # Load nvm immediately
export Z_LAZY_PYENV=false             # Load pyenv immediately
```

Available module toggles:

| Variable | Default | Effect |
|----------|---------|--------|
| `Z_ALIASES_ENABLED` | `true` | Load alias definitions |
| `Z_COMPLETION_ENABLED` | `true` | Enable tab completion |
| `Z_HISTORY_ENABLED` | `true` | Enable history management |
| `Z_KEYBINDINGS_ENABLED` | `true` | Custom key bindings |
| `Z_COMPILATION_ENABLED` | `false` | Compile scripts to .zwc |
| `Z_LAZY_ENABLED` | `true` | Lazy load tools |

## Customizing PATH

Add paths in `.zshlocal`:

```bash
# ~/.config/zsh/.zshlocal

# Prepend (highest priority)
export PATH="$HOME/bin:$PATH"

# Append (lowest priority)
export PATH="$PATH:/opt/custom/bin"

# Using the provided helper
_path_prepend "$HOME/my-tools/bin"
_path_append "/opt/vendor/bin"
```

## Environment Variables

Set project-specific or tool configuration:

```bash
# ~/.config/zsh/.zshlocal

# Editor preference
export EDITOR='nvim'
export VISUAL='code'

# Development
export GOPATH="$HOME/go"
export JAVA_HOME="/opt/homebrew/opt/openjdk"

# API keys (consider using a secrets manager)
export OPENAI_API_KEY="sk-..."
```

## Tool Configurations

### Starship Prompt

Edit `~/.config/starship.toml`:

```toml
# Customize prompt
[character]
success_symbol = "[>](bold green)"
error_symbol = "[x](bold red)"

[directory]
truncation_length = 3
```

See: [Starship Configuration](https://starship.rs/config/)

### Atuin History

Edit `~/.config/atuin/config.toml`:

```toml
# Customize history sync
search_mode = "fuzzy"
filter_mode = "host"
```

See: [Atuin Configuration](https://docs.atuin.sh/configuration/)

### FZF

Configure via environment variables in `.zshlocal`:

```bash
# ~/.config/zsh/.zshlocal

export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {}'"
```

## Common Recipes

### SSH Agent Auto-Start

```bash
# ~/.config/zsh/.zshlocal

# Start ssh-agent if not running
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
```

### Node Version Per Project

```bash
# ~/.config/zsh/.zshlocal

# Auto-switch node version when entering directory with .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
    if [[ -f .nvmrc && -d "$NVM_DIR" ]]; then
        nvm use 2>/dev/null
    fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
```

### Custom Prompt Section (Starship)

```toml
# ~/.config/starship.toml

# Add custom module
[custom.kubernetes]
command = "kubectl config current-context 2>/dev/null"
when = "kubectl config current-context 2>/dev/null"
symbol = "K8s:"
format = "[$symbol($output)]($style) "
style = "cyan"
```

### Directory-Specific Environment

```bash
# ~/.config/zsh/.zshlocal

# Load .env when entering project
autoload -U add-zsh-hook
load-local-env() {
    [[ -f .env ]] && source .env
}
add-zsh-hook chpwd load-local-env
```

## Debugging Customizations

Check if your changes are loaded:

```bash
# Verify alias exists
alias myalias

# Check function defined
type myfunction

# Verify PATH entry
echo $PATH | tr ':' '\n' | grep mypath

# Check environment variable
echo $MY_VAR

# Full health check
health
```

## Updating Without Losing Changes

When you run `zupdate`:

1. Core files (`.zshrc`, modules/) are updated
2. `.zshlocal` is preserved (gitignored)
3. Your customizations remain intact

If upgrading manually:

```bash
cd ~/.config/zsh
git stash           # Stash any local changes
git pull            # Pull updates
git stash pop       # Restore local changes (if any)
exec zsh            # Reload shell
```
