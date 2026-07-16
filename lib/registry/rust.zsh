#!/usr/bin/env zsh
# ==============================================================================
# RUST ECOSYSTEM REGISTRY
# Rust toolchain and package management.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'rust_cargo'            '$CARGO_HOME/bin:append:if_var_set:CARGO_HOME'
    'rust_cargo_default'    '$HOME/.cargo/bin:append:exists'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_RUST+=(
    'CARGO_HOME'          '$XDG_DATA_HOME/cargo|cargo'
    'RUSTUP_HOME'         '$XDG_DATA_HOME/rustup|rustup'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.cargo'   '$XDG_DATA_HOME/cargo|Set CARGO_HOME|true|cargo'
    '$HOME/.rustup'  '$XDG_DATA_HOME/rustup|Set RUSTUP_HOME|true|rustup'
)
