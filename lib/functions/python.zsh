#!/usr/bin/env zsh
# ==============================================================================
# ZSH PYTHON FUNCTIONS LIBRARY
# Python development and virtual environment utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_PYTHON_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_PYTHON_LOADED=1

# Configuration variables with defaults
: ${Z_FUNCTIONS_PYTHON_ENABLED:=true}  # Enable/disable Python functions (default: true)

# Exit early if Python functions are disabled
[[ "$Z_FUNCTIONS_PYTHON_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# VIRTUAL ENVIRONMENT MANAGEMENT
# ----------------------------------------------------------

# Activate Python virtual environment from common locations
# Usage: z_activate_venv
# Description: Searches for virtual environments in common locations:
#              venv, .venv, env, .env (in that order)
z_activate_venv() {
    # Try common virtual environment locations in order of preference
    local venv_locations=(
        "venv/bin/activate"
        ".venv/bin/activate"
        "env/bin/activate"
        ".env/bin/activate"
    )

    local venv_path
    for venv_path in "${venv_locations[@]}"; do
        if [[ -f "$venv_path" ]]; then
            echo "Activating virtual environment: $venv_path"
            source "$venv_path"
            echo "✓ Virtual environment activated"
            return 0
        fi
    done

    # No virtual environment found
    _ui_error "No virtual environment found in common locations"
    echo ""
    _ui_dim "Searched for:"
    _ui_dim "  - venv/bin/activate"
    _ui_dim "  - .venv/bin/activate"
    _ui_dim "  - env/bin/activate"
    _ui_dim "  - .env/bin/activate"
    echo ""
    _ui_dim "Create a virtual environment with:"
    _ui_dim "  python3 -m venv venv"
    echo ""
    _ui_dim "Or use one of the alternative names:"
    _ui_dim "  python3 -m venv .venv"
    return 1
}

_log DEBUG "ZSH Python Functions Library loaded"
