#!/usr/bin/env zsh
# ==============================================================================
# * ZSH INTERACTIVE SHELL CONFIGURATION
# ? Minimal ZSH configuration using Oh-My-Zsh and Starship prompt.
# ==============================================================================

# Profiling (comment out when not needed)
# zmodload zsh/zprof

# ----------------------------------------------------------
# * ZSH OPTIONS
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
# * PLUGINS
# ----------------------------------------------------------

plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
  dirhistory
  1password
  alias-finder
  encode64
  extract
  eza
  fzf
  fzf-tab
  gitignore
  gitfast
  zoxide
  sudo
  copypath
  copyfile
  jsontools
)

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
# * OH MY ZSH
# ? Load first to provide base functionality.
# ----------------------------------------------------------

# Update configuration
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Oh My Zsh Configuration
export ZSH="$XDG_DATA_HOME/oh-my-zsh"
export ZSH_THEME=""

# Set compdump path before OMZ (OMZ uses this; canonical definition in completion.zsh)
export ZSH_COMPDUMP="${ZSH_CACHE_HOME}/completion/zcompdump-${ZSH_VERSION}"

# Verify Oh My Zsh is installed
_require_omz || return 1

source "$ZSH/oh-my-zsh.sh"

# Validate essential tool dependencies for plugins
# ? These plugins require external binaries to function properly
for _tool in eza fzf zoxide; do
    if ! _has_cmd "$_tool"; then
        _log WARN "Plugin '$_tool' requires binary not found. Install: brew install $_tool"
    fi
done
unset _tool

# ----------------------------------------------------------
# * COMPILATION MODULE
# ? Automatically compiles ZSH scripts to bytecode (.zwc).
# ? Disabled by default - minimal benefit on modern SSDs.
#
# ? Configuration:
#     ZSH_COMPILATION_ENABLED          = true   (enable/disable compilation)
#     ZSH_COMPILATION_CLEANUP_ON_START = true   (run stale cleanup on shell start)
# ----------------------------------------------------------

export ZSH_COMPILATION_ENABLED=false
source "${ZSH_CONFIG_HOME}/modules/compilation.zsh"

# ----------------------------------------------------------
# * LAZY LOADING MODULE
# ? Defers command-based tool initialization until first use.
# ? Reduces startup time for: zoxide, nvm, pyenv, rbenv.
#
# ? Configuration:
#     ZSH_LAZY_ENABLED   = true   (enable/disable lazy loading)
#     ZSH_LAZY_ZOXIDE    = true   (lazy load zoxide)
#     ZSH_LAZY_NVM       = true   (lazy load nvm)
#     ZSH_LAZY_PYENV     = true   (lazy load pyenv)
#     ZSH_LAZY_RBENV     = true   (lazy load rbenv)
# ----------------------------------------------------------

source "${ZSH_CONFIG_HOME}/modules/lazy.zsh"

# ----------------------------------------------------------
# * COMPLETION MODULE
# ? Configures and optimizes ZSH tab completion system.
#
# ? Configuration:
#     ZSH_COMPLETION_ENABLED     = true   (enable/disable completion)
#     ZSH_COMPLETION_TTL         = 86400  (TTL for compdump in seconds)
#     ZSH_COMPLETION_MENU_SELECT = true   (enable menu selection)
# ----------------------------------------------------------

source "${ZSH_CONFIG_HOME}/modules/completion.zsh"

# ----------------------------------------------------------
# * HISTORY MODULE
# ? Advanced history management with security filtering.
# ? Provides backup, cleanup, stats, and interactive search.
#
# ? Configuration:
#     ZSH_HISTORY_ENABLED         = true    (enable/disable history)
#     ZSH_HISTORY_SIZE            = 100000  (commands in memory)
#     ZSH_HISTORY_SAVE_SIZE       = 100000  (commands saved to file)
#     ZSH_HISTORY_SECURITY_FILTER = true    (filter sensitive commands)
# ----------------------------------------------------------

source "${ZSH_CONFIG_HOME}/modules/history.zsh"

# ----------------------------------------------------------
# * ALIASES MODULE
# ? Centralized alias definitions with modern tool replacements.
# ? Loads last to override all previous aliases.
#
# ? Configuration:
#     ZSH_ALIASES_ENABLED        = true   (enable/disable aliases)
#     ZSH_ALIASES_MODERN_TOOLS   = true   (use modern tool replacements)
#     ZSH_ALIASES_SAFETY_PROMPTS = true   (add safety prompts)
# ----------------------------------------------------------

source "${ZSH_CONFIG_HOME}/modules/aliases.zsh"

# ----------------------------------------------------------
# * KEYBINDINGS MODULE
# ? Final keybinding configuration - loads LAST to override plugin defaults.
#
# ? Configuration:
#     ZSH_KEYBINDINGS_ENABLED = true   (enable/disable keybindings)
# ----------------------------------------------------------

source "${ZSH_CONFIG_HOME}/modules/keybindings.zsh"

# ----------------------------------------------------------
# * POST-INTERACTIVE HOOKS
# ? Run deferred initialization that must happen after /etc/zshrc.
# ? Hooks registered by modules: starship, editor config, PATH cleanup.
# ! IMPORTANT: Must run AFTER /etc/zshrc (which overwrites PROMPT on macOS).
# ----------------------------------------------------------

_run_post_interactive_hooks

# ----------------------------------------------------------
# * LOCAL CUSTOMIZATION
# ----------------------------------------------------------
# Source user's local config (not tracked in git)
if [[ -r "${ZDOTDIR}/local.zsh" ]]; then
    source "${ZDOTDIR}/local.zsh"
elif [[ -r "${HOME}/.zsh.local" ]]; then
    source "${HOME}/.zsh.local"
fi

# ----------------------------------------------------------
# * UPDATE CHECK
# ? Check for config updates in background (non-blocking).
#
# ? Configuration:
#     ZSH_UPDATE_CHECK_ENABLED  = true    (check for updates on launch)
#     ZSH_UPDATE_CHECK_INTERVAL = 86400   (seconds between checks)
# ----------------------------------------------------------

(( $+functions[_zsh_check_updates] )) && _zsh_check_updates

# Show profiling results
# zprof
