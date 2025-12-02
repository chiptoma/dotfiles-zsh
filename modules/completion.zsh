#!/usr/bin/env zsh
# ==============================================================================
# * ZSH COMPLETION MODULE
# ? Configures and optimizes ZSH tab completion system.
# ? Handles compinit, zstyle settings, and completion caching.
# ==============================================================================

# ----------------------------------------------------------
# * MODULE CONFIGURATION
# ----------------------------------------------------------

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_COMPLETION_LOADED} )) && return 0
typeset -g _ZSH_COMPLETION_LOADED=1

# Configuration variables with defaults
: ${ZSH_COMPLETION_ENABLED:=true}       # Enable/disable completion system
: ${ZSH_COMPLETION_TTL:=86400}          # TTL for compdump in seconds (24h)
: ${ZSH_COMPLETION_MENU_SELECT:=true}   # Enable menu selection

_log DEBUG "ZSH Completion Module loading"

# Exit early if module is disabled
if [[ "$ZSH_COMPLETION_ENABLED" != "true" ]]; then
    _log INFO "ZSH Completion Module disabled, skipping..."
    return 0
fi

# ----------------------------------------------------------
# * SHELL OPTIONS
# ? Completion-related shell behavior settings
# ----------------------------------------------------------

setopt ALWAYS_TO_END       # Move cursor to end after completion
setopt AUTO_MENU           # Show completion menu on tab press
setopt COMPLETE_IN_WORD    # Complete from cursor position
setopt NO_MENU_COMPLETE    # Don't autoselect first completion
setopt NO_LIST_BEEP        # Don't beep on ambiguous completion
setopt COMPLETE_ALIASES    # Complete aliases

# ----------------------------------------------------------
# * FPATH CONFIGURATION
# ? Must be set BEFORE compinit to register custom completions
# ----------------------------------------------------------

# Completion cache directory
ZSH_COMPLETION_CACHE_DIR="${ZSH_CACHE_HOME}/completion"
_ensure_dir "$ZSH_COMPLETION_CACHE_DIR"

# Compdump path (also set before OMZ in .zshrc for compatibility)
export ZSH_COMPDUMP="${ZSH_COMPLETION_CACHE_DIR}/zcompdump-${ZSH_VERSION}"

# Create completions directory if it doesn't exist
_ensure_dir "${ZSH_CONFIG_HOME}/completions"

# Add completion directories to fpath (only if they exist and not already present)
() {
    local dir
    local -a completion_dirs=(
        # User custom completions (highest priority)
        "${ZSH_CONFIG_HOME}/completions"
        "${ZDOTDIR}/completions"
        "${XDG_DATA_HOME}/zsh/completions"
        # OMZ completions (if OMZ is loaded)
        ${ZSH:+"$ZSH/custom/completions"}
        ${ZSH:+"$ZSH/completions"}
        # System-wide completions
        "/opt/homebrew/share/zsh/site-functions"
        "/usr/local/share/zsh/site-functions"
    )

    for dir in "${completion_dirs[@]}"; do
        # Skip empty entries, non-existent dirs, or already in fpath
        [[ -z "$dir" || ! -d "$dir" ]] && continue
        (( ${fpath[(Ie)$dir]} )) && continue
        fpath=("$dir" $fpath)
    done
}

# ----------------------------------------------------------
# * COMPINIT INITIALIZATION
# ? Load and configure the completion system with caching
# ----------------------------------------------------------

_log DEBUG "Initializing completion system..."

# Load zsh/stat module for efficient file stat (cross-platform)
zmodload -F zsh/stat b:zstat 2>/dev/null

# Load completion system
autoload -Uz compinit

# Initialize with TTL-based cache optimization
() {
    local dump_age=0

    if [[ -f "${ZSH_COMPDUMP}" ]]; then
        # Use zstat if available, fall back to external stat
        if (( ${+builtins[zstat]} )); then
            dump_age=$(( EPOCHSECONDS - $(zstat +mtime "${ZSH_COMPDUMP}") ))
        else
            local dump_mtime=$(stat -f %m "${ZSH_COMPDUMP}" 2>/dev/null || \
                               stat -c %Y "${ZSH_COMPDUMP}" 2>/dev/null || echo 0)
            dump_age=$(( EPOCHSECONDS - dump_mtime ))
        fi
    fi

    if [[ -f "${ZSH_COMPDUMP}" && $dump_age -le $ZSH_COMPLETION_TTL ]]; then
        compinit -C -d "${ZSH_COMPDUMP}"
    else
        compinit -d "${ZSH_COMPDUMP}"
    fi
}

# Enable bash completion compatibility (for AWS CLI, etc.)
autoload -Uz bashcompinit && bashcompinit

# Compile compdump for faster loading (if source is newer than .zwc)
if [[ -f "${ZSH_COMPDUMP}" && ( ! -f "${ZSH_COMPDUMP}.zwc" || "${ZSH_COMPDUMP}" -nt "${ZSH_COMPDUMP}.zwc" ) ]]; then
    zcompile "${ZSH_COMPDUMP}" 2>/dev/null && _log DEBUG "Compiled compdump"
fi

# ----------------------------------------------------------
# * BASIC COMPLETION SETTINGS
# ? Core zstyle configurations for completion behavior
# ----------------------------------------------------------

# Enable menu selection (if configured)
if [[ "$ZSH_COMPLETION_MENU_SELECT" == "true" ]]; then
    zstyle ':completion:*' menu select
fi

# Group completions by type
zstyle ':completion:*'              group-name       ''
zstyle ':completion:*:descriptions' format           '%B%F{yellow}── %d ──%f%b'
zstyle ':completion:*:messages'     format           '%B%F{magenta}── %d ──%f%b'
zstyle ':completion:*:warnings'     format           '%B%F{red}── no matches found ──%f%b'
zstyle ':completion:*:corrections'  format           '%B%F{green}── %d (errors: %e) ──%f%b'

# Show helpful descriptions for options
zstyle ':completion:*:options'      description      'yes'
zstyle ':completion:*:options'      auto-description '%d'

# Directory colors with highlighted selection (ma=7 = reverse video)
if [[ -n "$LS_COLORS" ]]; then
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" 'ma=7'
fi

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

# Don't complete uninteresting users (alphabetized)
zstyle ':completion:*:*:*:users' ignored-patterns \
    '_*' adm amanda apache at avahi avahi-autoipd beaglidx bin cacti \
    canna clamav daemon dbus distcache dnsmasq dovecot fax ftp games \
    gdm gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust \
    kdm ldap lp mail mailman mailnull man messagebus mldonkey mysql \
    nagios named netdump news nfsnobody nobody nscd ntp nut nx obsrun \
    openvpn operator pcap polkitd postfix postgres privoxy pulse pvm \
    quagga radvd rpc rpcuser rpm rtkit scard shutdown squid sshd statd \
    svn sync tftp usbmux uucp vcsa wwwrun xfs

# Ignore completion for commands we don't have
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# ----------------------------------------------------------
# * COMPLETION ENHANCEMENTS
# ? Advanced matching, fuzzy completion, and smart behaviors
# ----------------------------------------------------------

# Case-insensitive completion with partial-word matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Fuzzy completion
zstyle ':completion:*'              completer  _expand _complete _match _approximate
zstyle ':completion:*:match:*'      original   only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Partial completion suggestions
zstyle ':completion:*'              list-suffixes
zstyle ':completion:*'              expand        prefix suffix

# Show hidden files in completion
zstyle ':completion:*'              file-patterns '%p:globbed-files' '.*:hidden-files'

# Environment variable completion
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# History word completion
zstyle ':completion:*:history-words' stop            yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list            false
zstyle ':completion:*:history-words' menu            yes

# Man page completion by section
zstyle ':completion:*:manuals'          separate-sections true
zstyle ':completion:*:manuals.*'        insert-sections   true

# Better process completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*'           command     'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Kill signal completion
zstyle ':completion:*:*:kill:*'         menu        yes select
zstyle ':completion:*:kill:*'           force-list  always

# Better SSH/SCP host completion - don't use /etc/hosts
zstyle ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts off

# Better cd completion - don't complete parent directory
zstyle ':completion:*:cd:*'             ignore-parents parent pwd
zstyle ':completion:*:cd:*'             tag-order      local-directories directory-stack path-directories

# Archive format completion
zstyle ':completion:*:*:(gunzip|unzip|untar|tar|zip):*' file-patterns '*.(gz|bz2|xz|zip|tar|tgz|tbz2|7z|rar):compressed-files'

# Media file patterns
zstyle ':completion:*:*:mpv:*' file-patterns '*.(mp4|mkv|avi|mov|m4v|webm|mp3|flac|ogg|m4a|wav):media-files' '*(-/):directories'
zstyle ':completion:*:*:vlc:*' file-patterns '*.(mp4|mkv|avi|mov|m4v|webm|mp3|flac|ogg|m4a|wav):media-files' '*(-/):directories'

# ----------------------------------------------------------
# * PERFORMANCE OPTIMIZATIONS
# ? Caching and speed improvements for completion
# ----------------------------------------------------------

# Use cache for expensive completions
zstyle ':completion:*'              use-cache          on
zstyle ':completion:*'              cache-path         "${ZSH_COMPLETION_CACHE_DIR}/zcompcache"

# Accept exact matches even if ambiguous
zstyle ':completion:*'              accept-exact       '*(N)'
zstyle ':completion:*'              accept-exact-dirs  true

# Faster completion by avoiding expensive operations
zstyle ':completion:*'              use-perl           false
zstyle ':completion:*'              old-menu           false

# Rehash automatically for new commands
zstyle ':completion:*'              rehash             true

# ----------------------------------------------------------
# * TOOL-SPECIFIC COMPLETIONS
# ? External tool completions not covered by OMZ plugins
# ----------------------------------------------------------

# Helm (not in OMZ) - cached for faster startup
if _has_cmd helm; then
    _cache_eval "helm-completion" "helm completion zsh" "helm"
    _log DEBUG "Loaded Helm completions (cached)"
fi

# ----------------------------------------------------------
_log DEBUG "ZSH Completion Module loaded"
