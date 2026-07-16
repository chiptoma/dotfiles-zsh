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
# PLUGIN CONFIGURATION
# Plugins are self-managed (lib/plugins/index.zsh) — no Oh My Zsh.
# ----------------------------------------------------------

# Autosuggestions styling (read by zsh-autosuggestions when it loads)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200

# Compdump path (canonical definition in modules/04_completion.zsh)
export ZSH_COMPDUMP="${ZSH_CACHE_HOME}/completion/zcompdump-${ZSH_VERSION}"

# ----------------------------------------------------------
# INTERACTIVE MODULES & PLUGINS
# Plugins load between completion (compinit for fzf-tab) and the
# remaining modules; syntax highlighting is deferred to the tail.
# ----------------------------------------------------------
_z_prof_start; source "${ZSH_CONFIG_HOME}/modules/03_lazy.zsh";        _z_prof_end "03_lazy"
_z_prof_start; source "${ZSH_CONFIG_HOME}/modules/04_completion.zsh";  _z_prof_end "04_completion"
_z_prof_start; source "${ZSH_CONFIG_HOME}/lib/plugins/index.zsh";      _z_prof_end "plugins"
_z_prof_start; source "${ZSH_CONFIG_HOME}/modules/05_history.zsh";     _z_prof_end "05_history"
_z_prof_start; source "${ZSH_CONFIG_HOME}/modules/06_aliases.zsh";     _z_prof_end "06_aliases"
_z_prof_start; source "${ZSH_CONFIG_HOME}/modules/07_keybindings.zsh"; _z_prof_end "07_keybindings"

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

# One-shot warning for pre-rename settings (framework reads Z_*, not ZSH_*)
() {
    local _legacy
    for _legacy in ZSH_PATH_PROJECT_BIN ZSH_LOCALE_OVERRIDE ZSH_VERIFY_FILE_OWNERSHIP \
                   ZSH_HISTORY_SIZE ZSH_HISTORY_SECURITY_FILTER ZSH_LOG_LEVEL; do
        if (( ${(P)+_legacy} )); then
            _log WARN "Legacy setting $_legacy is ignored — rename to ${_legacy/#ZSH_/Z_} (see examples/zshlocal)"
        fi
    done
    return 0
}

# ----------------------------------------------------------
# SYNTAX HIGHLIGHTING (must be LAST to bind its widgets over everything)
# ----------------------------------------------------------
_z_prof_start
(( $+functions[_z_plugins_load_syntax_highlighting] )) && _z_plugins_load_syntax_highlighting
_z_prof_end "syntax-highlighting"

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

# Function-level profile report (Z_PROFILE_STARTUP=zprof)
if [[ "${Z_PROFILE_STARTUP:-}" == "zprof" ]]; then
    zprof
fi

# Leave a clean exit status for the first prompt
true
