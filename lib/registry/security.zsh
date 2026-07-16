#!/usr/bin/env zsh
# ==============================================================================
# SECURITY TOOLS REGISTRY
# GnuPG, pass, gopass.
# ==============================================================================

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_SECURITY+=(
    'GNUPGHOME'           '$XDG_DATA_HOME/gnupg|gpg'
    'PASSWORD_STORE_DIR'  '$XDG_DATA_HOME/pass|pass'
    'GOPASS_CONFIG'       '$XDG_CONFIG_HOME/gopass/config.yml|gopass'
    'GOPASS_HOMEDIR'      '$XDG_DATA_HOME/gopass|gopass'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.gnupg'          '$XDG_DATA_HOME/gnupg|Set GNUPGHOME|true|gpg'
    '$HOME/.password-store' '$XDG_DATA_HOME/pass|Set PASSWORD_STORE_DIR|true|pass'
)
