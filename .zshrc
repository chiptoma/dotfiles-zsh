#!/usr/bin/env zsh
# ==============================================================================
# ZSH INTERACTIVE SHELL CONFIGURATION
# ==============================================================================

# ----------------------------------------------------------
# ZSH OPTIONS
# ----------------------------------------------------------

# Performance optimizations
export DISABLE_MAGIC_FUNCTIONS=true
export DISABLE_UNTRACKED_FILES_DIRTY=true
export ENABLE_CORRECTION=false
export COMPLETION_WAITING_DOTS=true
export SHELL_SESSIONS_DISABLE=1

# Directory
setopt AUTO_CD                   # cd by typing directory name
setopt AUTO_PUSHD                # Push directories to stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicates
setopt PUSHD_SILENT              # Don't print directory stack

# Expansion and Globbing
setopt EXTENDED_GLOB             # Extended globbing
setopt NO_CASE_GLOB              # Case insensitive globbing
setopt NUMERIC_GLOB_SORT         # Sort numerically

# Input/Output
setopt NO_CLOBBER                # Don't overwrite files with >
setopt INTERACTIVE_COMMENTS      # Allow comments in interactive mode

# Job Control
setopt NO_BG_NICE                # Don't nice background jobs
setopt NO_HUP                    # Don't send HUP to jobs on exit
setopt NO_CHECK_JOBS             # Don't check jobs on exit

# Prompting
setopt PROMPT_SUBST              # Expand parameters in prompt

# Security
setopt NO_CORRECT                # Don't try to correct commands
setopt NO_CORRECT_ALL            # Don't try to correct arguments

# ----------------------------------------------------------
# PLUGINS
# ----------------------------------------------------------

plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
  dirhistory
  1password
  alias-finder
  encode64
  extract
  gitignore
  gitfast
  sudo
  copypath
  copyfile
  jsontools
)

# Tool-dependent plugins (only load if tool is installed)
(( $+commands[eza] )) && plugins+=(eza)
(( $+commands[fzf] )) && plugins+=(fzf fzf-tab)
(( $+commands[zoxide] )) && plugins+=(zoxide)

# Platform-specific plugins
if [[ "$OSTYPE" == "darwin"* ]]; then
  plugins+=(macos forklift brew)
fi

# Autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200

# Plugins configuration

# alias-finder
zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' longer yes
zstyle ':omz:plugins:alias-finder' exact yes
zstyle ':omz:plugins:alias-finder' cheaper yes

# eza
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'header' yes
zstyle ':omz:plugins:eza' 'show-group' yes
zstyle ':omz:plugins:eza' 'icons' yes
zstyle ':omz:plugins:eza' 'color-scale' all
zstyle ':omz:plugins:eza' 'color-scale-mode' fixed
zstyle ':omz:plugins:eza' 'size-prefix' si
zstyle ':omz:plugins:eza' 'time-style' "${TIME_STYLE:-relative}"
zstyle ':omz:plugins:eza' 'hyperlink' no

# ----------------------------------------------------------
# OH MY ZSH
# ----------------------------------------------------------
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Oh My Zsh Configuration
export ZSH="$XDG_DATA_HOME/oh-my-zsh"
export ZSH_THEME=""

# Set compdump path before OMZ (OMZ uses this; canonical definition in completion.zsh)
export ZSH_COMPDUMP="${ZSH_CACHE_HOME}/completion/zcompdump-${ZSH_VERSION}"

# Verify Oh My Zsh is installed
_require_omz || return 1

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# ----------------------------------------------------------
# COMPILATION MODULE
# Bytecode compilation disabled - minimal benefit on modern SSDs.
# ----------------------------------------------------------
export Z_COMPILATION_ENABLED=false
source "${ZSH_CONFIG_HOME}/modules/compilation.zsh"

# ----------------------------------------------------------
# INTERACTIVE MODULES
# ----------------------------------------------------------
source "${ZSH_CONFIG_HOME}/modules/lazy.zsh"
source "${ZSH_CONFIG_HOME}/modules/completion.zsh"
source "${ZSH_CONFIG_HOME}/modules/history.zsh"
source "${ZSH_CONFIG_HOME}/modules/aliases.zsh"
source "${ZSH_CONFIG_HOME}/modules/keybindings.zsh"

# ----------------------------------------------------------
# POST-INTERACTIVE HOOKS
# Run deferred initialization that must happen after /etc/zshrc.
# Hooks: _env_init_starship (prompt), _path_clean (cleanup).
# IMPORTANT: Must run AFTER /etc/zshrc (which overwrites PROMPT on macOS).
# ----------------------------------------------------------

_run_post_interactive_hooks

# ----------------------------------------------------------
# LOCAL CUSTOMIZATION
# ----------------------------------------------------------
# Source user's local config (not tracked in git)
if [[ -r "${ZDOTDIR}/.zshlocal" ]]; then
    source "${ZDOTDIR}/.zshlocal"
elif [[ -r "${HOME}/.zshlocal" ]]; then
    source "${HOME}/.zshlocal"
fi

# ----------------------------------------------------------
# UPDATE CHECK
# ----------------------------------------------------------
(( $+functions[_check_updates] )) && _check_updates

# ----------------------------------------------------------
# FIRST-RUN WELCOME
# Shows a welcome message on first interactive shell after install.
# ----------------------------------------------------------

if [[ ! -f "${ZSH_DATA_HOME}/.welcomed" ]] && _is_interactive; then
    echo ""
    echo "Welcome to ZSH Dotfiles! Run 'help' to get started."
    echo ""
    touch "${ZSH_DATA_HOME}/.welcomed" 2>/dev/null
fi

# Show profiling results
# zprof
