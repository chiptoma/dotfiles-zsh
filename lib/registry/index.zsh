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
# The ONLY declaration site for tool-category arrays; the master
# list drives declaration, the early env pass, and every consumer
# (modules/02_environment.zsh sources this file when standalone).
# ----------------------------------------------------------

# PATH definitions (consumed by modules/01_path.zsh)
typeset -gA Z_PATH_DEFINITIONS

# Master list of environment tool categories
typeset -ga Z_ENV_TOOL_CATEGORIES=(
    Z_ENV_TOOLS_ZSH
    Z_ENV_TOOLS_JS
    Z_ENV_TOOLS_GO
    Z_ENV_TOOLS_PYTHON
    Z_ENV_TOOLS_DOCKER
    Z_ENV_TOOLS_K8S
    Z_ENV_TOOLS_JVM
    Z_ENV_TOOLS_ANSIBLE
    Z_ENV_TOOLS_CLOUD
    Z_ENV_TOOLS_IAC
    Z_ENV_TOOLS_DB
    Z_ENV_TOOLS_VIRT
    Z_ENV_TOOLS_SECURITY
    Z_ENV_TOOLS_BUILD
    Z_ENV_TOOLS_LANGS
    Z_ENV_TOOLS_RUBY
    Z_ENV_TOOLS_RUST
    Z_ENV_TOOLS_GENERAL
)

# Declare every category (registry data files append to these)
() {
    local _cat
    for _cat in "${Z_ENV_TOOL_CATEGORIES[@]}"; do
        (( ${+parameters[$_cat]} )) || typeset -gA "$_cat"
    done
}

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
    for _category in "${Z_ENV_TOOL_CATEGORIES[@]}"; do
        for _var _val_cmd in ${(kvP)_category}; do
            _val="${_val_cmd%%|*}"
            # Skip if already set (respect user overrides from .zshenv/.zshlocal)
            [[ -n "${(P)_var:-}" ]] && continue
            export "$_var"="${(e)_val}"
        done
    done
}

_log DEBUG "ZSH Tool Registry loaded"
