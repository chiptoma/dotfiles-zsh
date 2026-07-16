#!/usr/bin/env zsh
# ==============================================================================
# ZSH TOOL REGISTRY LOADER
# Auto-discovers and sources all registry data files.
# Single source of truth for tool paths and environment variables.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_REGISTRY_LOADED} )) && return 0
typeset -g _Z_REGISTRY_LOADED=1

# ----------------------------------------------------------
# ARRAY DECLARATIONS
# Ensure arrays exist before registry files populate them.
# NOTE: modules/02_environment.zsh has fallback declarations for
# standalone sourcing. Keep both lists in sync.
# ----------------------------------------------------------

# PATH definitions (consumed by modules/01_path.zsh)
typeset -gA Z_PATH_DEFINITIONS

# Environment tool categories (consumed by modules/02_environment.zsh)
typeset -gA ZSH_ENV_TOOLS_ZSH
typeset -gA ZSH_ENV_TOOLS_JS
typeset -gA ZSH_ENV_TOOLS_GO
typeset -gA ZSH_ENV_TOOLS_PYTHON
typeset -gA ZSH_ENV_TOOLS_DOCKER
typeset -gA ZSH_ENV_TOOLS_K8S
typeset -gA ZSH_ENV_TOOLS_JVM
typeset -gA ZSH_ENV_TOOLS_ANSIBLE
typeset -gA ZSH_ENV_TOOLS_CLOUD
typeset -gA ZSH_ENV_TOOLS_IAC
typeset -gA ZSH_ENV_TOOLS_DB
typeset -gA ZSH_ENV_TOOLS_VIRT
typeset -gA ZSH_ENV_TOOLS_SECURITY
typeset -gA ZSH_ENV_TOOLS_BUILD
typeset -gA ZSH_ENV_TOOLS_LANGS
typeset -gA ZSH_ENV_TOOLS_RUBY
typeset -gA ZSH_ENV_TOOLS_RUST
typeset -gA ZSH_ENV_TOOLS_GENERAL

# Config file checks (consumed by modules/02_environment.zsh)
# Format: 'VAR' 'path|command' — only set if file exists AND command installed
typeset -gA Z_ENV_CONFIG_FILE_CHECKS

# XDG migration map (consumed by lib/functions/xdg.zsh)
# Format: key='$HOME/.stray_path' value='$XDG_TARGET|hint|movable|command'
typeset -gA Z_XDG_MIGRATIONS

# ----------------------------------------------------------
# AUTO-DISCOVERY LOADER
# Sources all .zsh files in this directory except index.zsh.
# Underscore-prefixed files load first (core before ecosystems).
# ----------------------------------------------------------

{
    local reg_dir="${ZSH_CONFIG_HOME}/lib/registry"
    local reg_file

    for reg_file in "${reg_dir}"/*.zsh(N); do
        [[ "${reg_file:t}" == "index.zsh" ]] && continue
        [[ -r "$reg_file" ]] && source "$reg_file"
    done
}

# ----------------------------------------------------------
# EARLY ENV PASS
# Set ALL env vars from registry data BEFORE path.zsh loads.
# This ensures if_var_set PATH conditions work on first boot.
# Vars for missing tools are cleaned up by _env_setup_tools().
# ----------------------------------------------------------

{
    local _category _var _val_cmd _val
    for _category in \
        ZSH_ENV_TOOLS_ZSH ZSH_ENV_TOOLS_JS ZSH_ENV_TOOLS_GO \
        ZSH_ENV_TOOLS_PYTHON ZSH_ENV_TOOLS_DOCKER ZSH_ENV_TOOLS_K8S \
        ZSH_ENV_TOOLS_JVM ZSH_ENV_TOOLS_ANSIBLE ZSH_ENV_TOOLS_CLOUD \
        ZSH_ENV_TOOLS_IAC ZSH_ENV_TOOLS_DB ZSH_ENV_TOOLS_VIRT \
        ZSH_ENV_TOOLS_SECURITY ZSH_ENV_TOOLS_BUILD ZSH_ENV_TOOLS_LANGS \
        ZSH_ENV_TOOLS_RUBY ZSH_ENV_TOOLS_RUST ZSH_ENV_TOOLS_GENERAL; do
        for _var _val_cmd in ${(kvP)_category}; do
            _val="${_val_cmd%%|*}"
            # Skip if already set (respect user overrides from .zshenv/.zshlocal)
            [[ -n "${(P)_var:-}" ]] && continue
            export "$_var"="${(e)_val}"
        done
    done
}

_log DEBUG "ZSH Tool Registry loaded"
