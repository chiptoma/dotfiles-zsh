#!/usr/bin/env zsh
# ==============================================================================
# ZSH DOCKER FUNCTIONS LIBRARY
# Docker container and image management utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_DOCKER_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_DOCKER_LOADED=1

# ----------------------------------------------------------
# DOCKER CLEANUP
# Unified cleanup for containers, images, and volumes.
# ----------------------------------------------------------

# Clean up Docker resources by type
# Usage: z_docker_cleanup <stop|rmi|rmv>
#   stop - Stop all running containers
#   rmi  - Remove dangling images
#   rmv  - Remove dangling volumes
z_docker_cleanup() {
    local subcmd="${1:?Usage: z_docker_cleanup <stop|rmi|rmv>}"

    # Validate arguments before environment: usage errors must not depend
    # on whether docker happens to be installed
    case "$subcmd" in
        stop|rmi|rmv) ;;
        *)
            _ui_error "Unknown subcommand: $subcmd"
            _ui_dim "Usage: z_docker_cleanup <stop|rmi|rmv>"
            return 1
            ;;
    esac

    if ! _has_cmd docker; then
        _ui_error "docker command not found"
        _ui_dim "Install: https://docs.docker.com/get-docker/ or 'brew install --cask docker'"
        return 1
    fi

    local -a items=()
    local label docker_cmd

    case "$subcmd" in
        stop)
            items=("${(@f)$(docker ps -q)}")
            label="container"
            docker_cmd="docker stop"
            ;;
        rmi)
            items=("${(@f)$(docker images -q -f dangling=true)}")
            label="dangling image"
            docker_cmd="docker rmi"
            ;;
        rmv)
            items=("${(@f)$(docker volume ls -q -f dangling=true)}")
            label="dangling volume"
            docker_cmd="docker volume rm"
            ;;
        *)
            _ui_error "Unknown subcommand: $subcmd"
            _ui_dim "Usage: z_docker_cleanup <stop|rmi|rmv>"
            return 1
            ;;
    esac

    # Filter empty entries: ${(f)...} on empty string creates ("") not ()
    items=("${(@)items:#}")

    if (( ${#items} == 0 )); then
        echo "No ${label}s to clean up"
        return 0
    fi

    echo "Cleaning up ${#items} ${label}(s)..."
    if ${=docker_cmd} "${items[@]}"; then
        _ui_ok "${#items} ${label}(s) cleaned up"
    else
        _ui_warn "Some ${label}s may have failed to clean up"
        return 1
    fi
}

_log DEBUG "ZSH Docker Functions Library loaded"
