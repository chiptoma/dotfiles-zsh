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
# zoxide: 04_lazy.zsh handles deferred init (faster than OMZ's eager plugin)

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

# Set compdump path before OMZ (OMZ uses this; canonical definition in 05_completion.zsh)
export ZSH_COMPDUMP="${ZSH_CACHE_HOME}/completion/zcompdump-${ZSH_VERSION}"

# Load Oh My Zsh (optional — shell degrades gracefully without it)
if [[ -d "$ZSH" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    # OMZ not installed — provide minimal fallback so shell stays usable
    autoload -Uz compinit && compinit -d "${ZSH_COMPDUMP}"
    if [[ -t 1 ]]; then
        print -P "%F{yellow}Warning:%f Oh My Zsh not found at $ZSH. Plugins disabled."
        print -P "Install: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    fi
fi

# ----------------------------------------------------------
# INTERACTIVE MODULES
# ----------------------------------------------------------
source "${ZSH_CONFIG_HOME}/modules/03_lazy.zsh"
source "${ZSH_CONFIG_HOME}/modules/04_completion.zsh"
source "${ZSH_CONFIG_HOME}/modules/05_history.zsh"
source "${ZSH_CONFIG_HOME}/modules/06_aliases.zsh"
source "${ZSH_CONFIG_HOME}/modules/07_keybindings.zsh"

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
# _safe_source handles readability check + optional ownership verification
_safe_source "${ZDOTDIR}/.zshlocal" || _safe_source "${HOME}/.zshlocal"

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
