#!/usr/bin/env zsh
# ==============================================================================
# PLUGIN LOADER
# Self-managed zsh plugins — no framework dependency (Oh My Zsh removed).
# ------------------------------------------------------------------------------
# Load order matters: fzf-tab needs compinit to have run (04_completion),
#   and zsh-syntax-highlighting must be sourced LAST — .zshrc calls
#   _z_plugins_load_syntax_highlighting at its tail for that reason.
# ==============================================================================

# Idempotent guard
(( ${+_Z_PLUGINS_LOADED} )) && return 0
typeset -g _Z_PLUGINS_LOADED=1

# Plugin clones live here (installer-managed: git clone --depth=1)
: ${Z_PLUGINS_DIR:="${ZSH_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh}/plugins"}

# Pre-native installs cloned plugins into OMZ's custom dir; honor them
# for one release so `--update` doesn't break existing machines
typeset -g _Z_PLUGINS_LEGACY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh/custom/plugins"

# Sources a plugin entry file from the native dir, then the legacy dir
_z_plugin_source() {
    local name="$1" file="$2"
    if [[ -r "$Z_PLUGINS_DIR/$name/$file" ]]; then
        source "$Z_PLUGINS_DIR/$name/$file"
    elif [[ -r "$_Z_PLUGINS_LEGACY_DIR/$name/$file" ]]; then
        source "$_Z_PLUGINS_LEGACY_DIR/$name/$file"
    else
        _log DEBUG "Plugin not installed: $name"
        return 1
    fi
}

# ----------------------------------------------------------
# PLUGINS (order-sensitive)
# ----------------------------------------------------------

# fzf-tab: replaces the completion menu — after compinit, before wrappers
_has_cmd fzf && _z_plugin_source fzf-tab fzf-tab.plugin.zsh

# Autosuggestions (styling via ZSH_AUTOSUGGEST_* in .zshrc)
_z_plugin_source zsh-autosuggestions zsh-autosuggestions.zsh

# fzf shell bindings: Ctrl+R history, Ctrl+T files, Alt+C cd (cached init)
_has_cmd fzf && _cache_eval "fzf" "fzf --zsh" "fzf"

# 1Password CLI completion (cached init)
_has_cmd op && _cache_eval "op" "op completion zsh" "op"

# Vendored widgets (formerly OMZ plugins; MIT — see file headers)
source "${ZSH_CONFIG_HOME}/lib/plugins/vendor/dirhistory.zsh"
source "${ZSH_CONFIG_HOME}/lib/plugins/vendor/sudo.zsh"

# ----------------------------------------------------------
# DEFERRED: SYNTAX HIGHLIGHTING
# Must bind its widgets after every other ZLE change; .zshrc calls
# this at the very end of interactive startup.
# ----------------------------------------------------------

_z_plugins_load_syntax_highlighting() {
    _z_plugin_source zsh-syntax-highlighting zsh-syntax-highlighting.zsh
}

_log DEBUG "ZSH Plugin Loader loaded"
