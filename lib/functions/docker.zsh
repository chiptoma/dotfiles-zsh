#!/usr/bin/env zsh
# ==============================================================================
# ZSH DOCKER FUNCTIONS LIBRARY
# Docker container and image management utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_DOCKER_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_DOCKER_LOADED=1

# Configuration variables with defaults
: ${Z_FUNCTIONS_DOCKER_ENABLED:=true}  # Enable/disable Docker functions (default: true)

# Exit early if Docker functions are disabled
[[ "$Z_FUNCTIONS_DOCKER_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# DOCKER CONTAINER MANAGEMENT
# ----------------------------------------------------------

# Stop all running Docker containers
# Usage: z_docker_stop_all
z_docker_stop_all() {
    if ! _has_cmd docker; then
        _ui_error "docker command not found"
        _ui_dim "Install: https://docs.docker.com/get-docker/ or 'brew install --cask docker'"
        return 1
    fi

    # Filter empty entries: ${(f)...} on empty string creates ("") not ()
    local -a containers=("${(@f)$(docker ps -q)}")
    containers=("${(@)containers:#}")  # Remove empty elements
    if (( ${#containers} )); then
        echo "Stopping ${#containers} container(s)..."
        if docker stop "${containers[@]}"; then
            echo "✓ All containers stopped"
        else
            echo "Warning: Some containers may have failed to stop" >&2
            return 1
        fi
    else
        echo "No running containers to stop"
    fi
}

# ----------------------------------------------------------
# DOCKER IMAGE MANAGEMENT
# ----------------------------------------------------------

# Remove dangling Docker images
# Usage: z_docker_rmi_dangling
z_docker_rmi_dangling() {
    if ! _has_cmd docker; then
        _ui_error "docker command not found"
        _ui_dim "Install: https://docs.docker.com/get-docker/ or 'brew install --cask docker'"
        return 1
    fi

    # Filter empty entries: ${(f)...} on empty string creates ("") not ()
    local -a images=("${(@f)$(docker images -q -f dangling=true)}")
    images=("${(@)images:#}")  # Remove empty elements
    if (( ${#images} )); then
        echo "Removing ${#images} dangling image(s)..."
        if docker rmi "${images[@]}"; then
            echo "✓ Dangling images removed"
        else
            echo "⚠ Some images may have failed to remove" >&2
            return 1
        fi
    else
        echo "No dangling images to remove"
    fi
}

# ----------------------------------------------------------
# DOCKER VOLUME MANAGEMENT
# ----------------------------------------------------------

# Remove dangling Docker volumes
# Usage: z_docker_rmv_dangling
z_docker_rmv_dangling() {
    if ! _has_cmd docker; then
        _ui_error "docker command not found"
        _ui_dim "Install: https://docs.docker.com/get-docker/ or 'brew install --cask docker'"
        return 1
    fi

    # Filter empty entries: ${(f)...} on empty string creates ("") not ()
    local -a volumes=("${(@f)$(docker volume ls -q -f dangling=true)}")
    volumes=("${(@)volumes:#}")  # Remove empty elements
    if (( ${#volumes} )); then
        echo "Removing ${#volumes} dangling volume(s)..."
        docker volume rm "${volumes[@]}"
        echo "✓ Dangling volumes removed"
    else
        echo "No dangling volumes to remove"
    fi
}

_log DEBUG "ZSH Docker Functions Library loaded"
