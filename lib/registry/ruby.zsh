#!/usr/bin/env zsh
# ==============================================================================
# RUBY ECOSYSTEM REGISTRY
# Ruby runtimes, version managers, and package managers.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'rb_rbenv_root'         '$RBENV_ROOT/bin:append:if_var_set:RBENV_ROOT'
    'rb_rbenv_shims'        '$RBENV_ROOT/shims:append:if_var_set:RBENV_ROOT'
    'rb_rbenv_default'      '$HOME/.rbenv/bin:append:exists'
    'rb_rbenv_shims_def'    '$HOME/.rbenv/shims:append:exists'
    'rb_rvm'                '$rvm_path/bin:append:if_var_set:rvm_path'
    'rb_rvm_default'        '$HOME/.rvm/bin:append:exists'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

Z_ENV_TOOLS_RUBY+=(
    'GEM_HOME'            '$XDG_DATA_HOME/gem|gem'
    'GEM_SPEC_CACHE'      '$XDG_CACHE_HOME/gem|gem'
    'BUNDLE_USER_CONFIG'  '$XDG_CONFIG_HOME/bundle|bundle'
    'BUNDLE_USER_CACHE'   '$XDG_CACHE_HOME/bundle|bundle'
    'BUNDLE_USER_PLUGIN'  '$XDG_DATA_HOME/bundle|bundle'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.rbenv'  '$XDG_DATA_HOME/rbenv|Set RBENV_ROOT|true|rbenv'
    '$HOME/.gem'    '$XDG_DATA_HOME/gem|Set GEM_HOME|true|gem'
)
