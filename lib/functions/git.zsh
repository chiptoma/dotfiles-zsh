#!/usr/bin/env zsh
# ==============================================================================
# ZSH GIT FUNCTIONS LIBRARY
# Git workflow and repository management utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_GIT_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_GIT_LOADED=1

# Configuration variables with defaults
: ${Z_FUNCTIONS_GIT_ENABLED:=true}  # Enable/disable Git functions (default: true)

# Exit early if Git functions are disabled
[[ "$Z_FUNCTIONS_GIT_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# GIT BRANCH MANAGEMENT
# ----------------------------------------------------------

# Clean up merged git branches safely
# Usage: z_git_cleanup
# Description: Removes local branches that have been merged into current branch
#              Protects main, master, and develop branches
z_git_cleanup() {
    if ! _has_cmd git; then
        _ui_error "git command not found"
        return 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        _ui_error "Not a git repository"
        return 1
    fi

    # Get list of merged branches (excluding main, master, develop, and current branch)
    local merged_branches=$(git branch --merged | grep -v "\*" | grep -v "main" | grep -v "master" | grep -v "develop")

    if [[ -n "$merged_branches" ]]; then
        echo "Found merged branches to clean up:"
        echo "$merged_branches"
        echo ""

        # Delete each branch (while loop is safer than xargs for special chars)
        local branch
        local -i deleted=0 failed=0
        while IFS= read -r branch; do
            # Trim leading/trailing whitespace
            branch="${branch#"${branch%%[![:space:]]*}"}"
            branch="${branch%"${branch##*[![:space:]]}"}"
            [[ -z "$branch" ]] && continue

            if git branch -d "$branch" 2>/dev/null; then
                ((deleted++))
            else
                echo "  Failed to delete: $branch" >&2
                ((failed++))
            fi
        done <<< "$merged_branches"

        echo ""
        if (( failed > 0 )); then
            echo "✓ Cleaned up $deleted branch(es), $failed failed"
        else
            echo "✓ Merged branches cleaned up ($deleted deleted)"
        fi
    else
        echo "No merged branches to clean up"
    fi
}

# ----------------------------------------------------------
# GIT REPOSITORY INFORMATION
# ----------------------------------------------------------

# Get the size of a git repository (including .git)
# Usage: z_gitsize [path]
z_gitsize() {
    local repo="${1:-.}"

    if ! _has_cmd git; then
        _ui_error "git command not found"
        return 1
    fi

    if [[ ! -d "$repo/.git" ]]; then
        _ui_error "Not a git repository"
        return 1
    fi

    # Use z_sizeof from file.zsh
    z_sizeof "$repo"
}

_log DEBUG "ZSH Git Functions Library loaded"
