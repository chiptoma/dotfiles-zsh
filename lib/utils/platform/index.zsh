#!/usr/bin/env zsh
# ==============================================================================
# * ZSH PLATFORM UTILS BARREL
# ? Loads platform-specific utilities based on $OSTYPE.
# ==============================================================================

# Load platform-specific library
if [[ "$OSTYPE" == darwin* ]]; then
    [[ -r "${0:A:h}/macos.zsh" ]] && source "${0:A:h}/macos.zsh"
elif [[ "$OSTYPE" == linux* ]]; then
    [[ -r "${0:A:h}/linux.zsh" ]] && source "${0:A:h}/linux.zsh"
elif [[ "$OSTYPE" == freebsd* || "$OSTYPE" == openbsd* || "$OSTYPE" == netbsd* ]]; then
    [[ -r "${0:A:h}/bsd.zsh" ]] && source "${0:A:h}/bsd.zsh"
fi
