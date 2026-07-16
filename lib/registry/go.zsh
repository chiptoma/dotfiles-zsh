#!/usr/bin/env zsh
# ==============================================================================
# GO ECOSYSTEM REGISTRY
# Go toolchain and module management.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'go_path'               '$GOPATH/bin:append:if_var_set:GOPATH'
    'go_default'            '$HOME/go/bin:append:exists'
    'go_local_share'        '$HOME/.local/share/go/bin:append:exists'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

Z_ENV_TOOLS_GO+=(
    'GOPATH'        '$XDG_DATA_HOME/go|go'
    'GOCACHE'       '$XDG_CACHE_HOME/go|go'
    'GOMODCACHE'    '$XDG_CACHE_HOME/go-mod|go'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/go'  '$XDG_DATA_HOME/go|Set GOPATH|true|go'
)
