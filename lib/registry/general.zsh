#!/usr/bin/env zsh
# ==============================================================================
# GENERAL TOOLS REGISTRY
# Build tools, terminal utilities, and miscellaneous tools.
# ==============================================================================

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

# Build Tools
ZSH_ENV_TOOLS_BUILD+=(
    'CCACHE_DIR'         '$XDG_CACHE_HOME/ccache|ccache'
    'CCACHE_CONFIGPATH'  '$XDG_CONFIG_HOME/ccache/config|ccache'
    'PKG_CONFIG_PATH'    '$XDG_DATA_HOME/pkgconfig:$XDG_DATA_HOME/lib/pkgconfig|pkg-config'
)

# General Tools (remaining entries not covered by ecosystem files)
ZSH_ENV_TOOLS_GENERAL+=(
    'HTOPRC'              '$XDG_CONFIG_HOME/htop/htoprc|htop'
    'TMUX_TMPDIR'         '$XDG_RUNTIME_DIR/tmux|tmux'
    'SCREENRC'            '$XDG_CONFIG_HOME/screen/screenrc|screen'
    'PARALLEL_HOME'       '$XDG_CONFIG_HOME/parallel|parallel'
)

# ----------------------------------------------------------
# CONFIG FILE CHECKS
# Only set if file exists (tools error on missing config files)
# ----------------------------------------------------------

Z_ENV_CONFIG_FILE_CHECKS+=(
    'WGETRC'   '$XDG_CONFIG_HOME/wgetrc|wget'
    'INPUTRC'  '$XDG_CONFIG_HOME/readline/inputrc|readline'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.parallel'  '$XDG_CONFIG_HOME/parallel|Set PARALLEL_HOME|true|parallel'
    '$HOME/.lesshst'   '$XDG_STATE_HOME/less/history|Set LESSHISTFILE|true|less'
    '$HOME/.cups'      '$XDG_CONFIG_HOME/cups|Symlink if CUPS < 3.0|true|lp|symlink_if_old'
)
