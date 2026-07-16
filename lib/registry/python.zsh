#!/usr/bin/env zsh
# ==============================================================================
# PYTHON ECOSYSTEM REGISTRY
# Python runtimes, version managers, and package managers.
# ==============================================================================

# ----------------------------------------------------------
# PATH DEFINITIONS
# ----------------------------------------------------------

Z_PATH_DEFINITIONS+=(
    'py_pyenv_root'         '$PYENV_ROOT/bin:append:if_var_set:PYENV_ROOT'
    'py_pyenv_shims'        '$PYENV_ROOT/shims:append:if_var_set:PYENV_ROOT'
    'py_pyenv_default'      '$HOME/.pyenv/bin:append:exists'
    'py_pyenv_shims_def'    '$HOME/.pyenv/shims:append:exists'
    'py_poetry'             '$POETRY_HOME/bin:append:if_var_set:POETRY_HOME'
    'py_poetry_default'     '$HOME/.poetry/bin:append:exists'
    'py_rye'                '$RYE_HOME/shims:append:if_var_set:RYE_HOME'
    'py_rye_default'        '$HOME/.rye/shims:append:exists'
)

# ----------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------

ZSH_ENV_TOOLS_PYTHON+=(
    'PYTHONSTARTUP'      '$XDG_CONFIG_HOME/python/python_startup.py|python'
    'PYTHON_HISTORY'     '$XDG_STATE_HOME/python_history|python'
    'PIP_CACHE_DIR'      '$XDG_CACHE_HOME/pip|pip'
    'PIPENV_CACHE_DIR'   '$XDG_CACHE_HOME/pipenv|pipenv'
    'POETRY_HOME'        '$XDG_DATA_HOME/poetry|poetry'
    'POETRY_CACHE_DIR'   '$XDG_CACHE_HOME/poetry|poetry'
    'PYENV_ROOT'         '$XDG_DATA_HOME/pyenv|pyenv'
    'WORKON_HOME'        '$XDG_DATA_HOME/virtualenvs|virtualenv'
    'VIRTUALENV_CONFIG_FILE' '$XDG_CONFIG_HOME/virtualenv/virtualenv.ini|virtualenv'
    'JUPYTER_RUNTIME_DIR' '$XDG_RUNTIME_DIR/jupyter|jupyter'
    'IPYTHONDIR'         '$XDG_CONFIG_HOME/ipython|ipython'
    'PIPX_HOME'          '$XDG_DATA_HOME/pipx|pipx'
)

# Jupyter config (General Tools category for display)
ZSH_ENV_TOOLS_GENERAL+=(
    'JUPYTER_CONFIG_DIR'  '$XDG_CONFIG_HOME/jupyter|jupyter'
)

# ----------------------------------------------------------
# XDG MIGRATIONS
# ----------------------------------------------------------

Z_XDG_MIGRATIONS+=(
    '$HOME/.pyenv'            '$XDG_DATA_HOME/pyenv|Set PYENV_ROOT|true|pyenv'
    '$HOME/.local/pipx'       '$XDG_DATA_HOME/pipx|Set PIPX_HOME|true|pipx'
    '$HOME/.poetry'           '$XDG_DATA_HOME/poetry|Set POETRY_HOME|true|poetry'
    '$HOME/.rye'              '$XDG_DATA_HOME/rye|Set RYE_HOME|true|rye'
    '$HOME/.python_history'   '$XDG_STATE_HOME/python_history|Set PYTHON_HISTORY|true|python3'
    '$HOME/.ipython'          '$XDG_CONFIG_HOME/ipython|Set IPYTHONDIR|true|ipython'
    '$HOME/.jupyter'          '$XDG_CONFIG_HOME/jupyter|Set JUPYTER_CONFIG_DIR|true|jupyter'
)
