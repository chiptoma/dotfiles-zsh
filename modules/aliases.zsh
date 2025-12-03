#!/usr/bin/env zsh
# ==============================================================================
# * ZSH ALIASES MODULE
# ? Centralized alias definitions with modern tool replacements
# ? Organized by category: Safety > Navigation > Files > Tools > Development
# ? Inline comments after aliases are parsed by `als` for descriptions
# ==============================================================================

# ----------------------------------------------------------
# * MODULE CONFIGURATION
# ----------------------------------------------------------

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_ALIASES_LOADED} )) && return 0
typeset -g _ZSH_ALIASES_LOADED=1

# Configuration variables with defaults
: ${ZSH_ALIASES_ENABLED:=true}        # Enable/disable aliases (default: true)
: ${ZSH_ALIASES_MODERN_TOOLS:=true}   # Use modern tool replacements (default: true)
: ${ZSH_ALIASES_SAFETY_PROMPTS:=true} # Add safety prompts to destructive commands (default: true)

_log DEBUG "ZSH Aliases Module loading"

# Exit early if aliases are disabled
if [[ "$ZSH_ALIASES_ENABLED" != "true" ]]; then
    _log INFO "ZSH Aliases Module disabled, skipping"
    return 0
fi

# ----------------------------------------------------------
# * SAFETY ALIASES
# ? Interactive shell only - prevent accidental data loss
# ----------------------------------------------------------

if [[ "$ZSH_ALIASES_SAFETY_PROMPTS" == "true" ]] && [[ $- == *i* ]]; then
    alias cp='cp -i'          # Copy with confirmation prompt
    alias mv='mv -i'          # Move with confirmation prompt
    alias rm='rm -i'          # Remove with confirmation prompt
    alias chmod='chmod -v'    # Change permissions (verbose)
    alias chown='chown -v'    # Change ownership (verbose)

    if _has_cmd trash; then
        alias rmt='trash'     # Move to trash instead of delete
    fi

    _log DEBUG "Safety aliases configured"
fi

# ----------------------------------------------------------
# * NAVIGATION
# ? Directory traversal and jumping
# ----------------------------------------------------------

alias ..='cd ..'            # Go up 1 directory
alias ...='cd ../..'        # Go up 2 directories
alias ....='cd ../../..'    # Go up 3 directories
alias .....='cd ../../../..'  # Go up 4 directories
alias -- -='cd -'           # Go to previous directory

alias home='cd ~'                       # Jump to home directory
alias dld='cd ~/Downloads'              # Jump to Downloads
alias dsk='cd ~/Desktop'                # Jump to Desktop
alias doc='cd ~/Documents'              # Jump to Documents

alias mkcd='zsh_mkcd'       # Create directory and cd into it
alias take='zsh_mkcd'       # Create directory and cd into it
alias up='zsh_up'           # Navigate up N directories

alias d='dirs -v | head -10'  # Show directory stack
alias p='pushd'               # Push directory to stack

if _has_cmd zoxide; then
    alias zz='z -'  # Zoxide: go to previous directory
    alias zb='z -'  # Zoxide: go back to previous directory
fi

# ----------------------------------------------------------
# * FILE OPERATIONS
# ? File and directory manipulation
# ----------------------------------------------------------

alias md='mkdir -p'  # Create nested directories
alias rd='rmdir'     # Remove empty directory

alias clr='clear'  # Clear terminal screen
alias cls='clear'  # Clear terminal screen
alias cl='clear'   # Clear terminal screen
alias c='clear'    # Clear terminal screen

alias j='jobs -l'  # List background jobs with PIDs

alias sizeof='zsh_sizeof'    # Show size of file/directory
alias backup='zsh_backup'    # Create timestamped backup
alias todos='zsh_todos'      # Find TODO/FIXME comments
alias extract='zsh_extract'  # Universal archive extractor
alias gitsize='zsh_gitsize'  # Show git-tracked file sizes

if ! type which >/dev/null 2>&1; then
    alias which='type -a'  # Show command locations
fi

# ----------------------------------------------------------
# * DIRECTORY LISTING
# ? Basic ls aliases (overridden by OMZ eza plugin if installed)
# ----------------------------------------------------------

# Platform-aware ls color
if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'        # macOS: BSD ls color flag
else
    alias ls='ls --color=auto'  # Linux: GNU ls color flag
fi

alias l='ls -lah'   # List all, human-readable
alias ll='ls -lh'   # Long format, human-readable
alias la='ls -lAh'  # Long + hidden (except . ..)

# ----------------------------------------------------------
# * FILE MANAGER
# ? Yazi with cd-on-exit (function in lib/functions/file.zsh)
# ----------------------------------------------------------

if _has_cmd yazi; then
    alias y='zsh_yazi'  # Yazi file manager
fi

# ----------------------------------------------------------
# * MODERN TOOL REPLACEMENTS
# ? Rust-powered CLI alternatives
# ----------------------------------------------------------

if [[ "$ZSH_ALIASES_MODERN_TOOLS" == "true" ]]; then

    # ─── REPLACEMENTS ───
    if _has_cmd eza; then
        alias lt='eza --tree --level=2 --icons'       # Tree view (2 levels)
        alias lta='eza --tree --level=2 -la --icons'  # Tree view all (2 levels)
        alias ltd='eza --tree --level=3 --icons'      # Tree view (3 levels)
        alias ltda='eza --tree --level=3 -la --icons' # Tree view all (3 levels)
    elif _has_cmd tree; then
        # ? Fallback to standard tree if eza not installed
        alias lt='tree -L 2'                          # Tree view (2 levels)
        alias lta='tree -L 2 -a'                      # Tree view all (2 levels)
        alias ltd='tree -L 3'                         # Tree view (3 levels)
        alias ltda='tree -L 3 -a'                     # Tree view all (3 levels)
    fi

    if _has_cmd bat; then
        alias cat='bat'                   # Better cat with syntax highlighting
        alias catp='bat --style=plain'    # Cat plain (no decorations)
        alias catn='bat --style=numbers'  # Cat with line numbers
    fi

    if _has_cmd fd; then
        alias find='fd'             # Modern find (fd)
        alias f='fd'                # Quick file search
        alias fde='fd --extension'  # Find by extension
    fi

    if _has_cmd dust; then
        alias du='dust'                # Disk usage with visual bars
        alias duhere='dust --depth 2'  # Disk usage (2 levels)
    fi

    if _has_cmd duf; then
        alias df='duf'         # Disk free space (pretty)
        alias dfall='duf --all'  # Show all filesystems
    fi

    # ─── SYSTEM STATS ───
    if _has_cmd btm; then
        alias top='btm'   # Modern system monitor
        alias htop='btm'  # Modern system monitor
    fi

    if _has_cmd procs; then
        alias pst='procs --color always --tree'        # Process tree view
        alias pscpu='procs --color always --sortd cpu' # Processes by CPU
        alias psmem='procs --color always --sortd mem' # Processes by memory
    fi

    if _has_cmd bandwhich; then
        alias bandwidth='sudo bandwhich'  # Bandwidth monitor by process
        alias netmon='sudo bandwhich'     # Network traffic monitor
    fi

    # ─── SEARCH & FIND ───
    if _has_cmd rg; then
        alias rgi='rg -i'  # Ripgrep case-insensitive
        alias rgf='rg -F'  # Ripgrep fixed string
        alias rgl='rg -l'  # Ripgrep list files only
        alias rgc='rg -c'  # Ripgrep count matches
    else
        alias grep='grep --color=auto'    # Grep with colors
        alias egrep='egrep --color=auto'  # Extended grep with colors
        alias fgrep='fgrep --color=auto'  # Fixed grep with colors
    fi

    if _has_cmd delta; then
        alias diffs='delta --side-by-side'  # Side-by-side diff
    fi

    # ─── PRODUCTIVITY ───
    if _has_cmd gping; then
        alias ping='gping --clear'  # Visual ping with graph
    fi

    if _has_cmd trip; then
        alias traceroute='trip -u'  # Visual traceroute TUI
        alias trippy='trip -u'      # Visual traceroute TUI
    fi

    if _has_cmd xh; then
        alias http='xh --pretty all'         # HTTP client (pretty)
        alias https='xh --https --pretty all'  # HTTPS client (pretty)
    fi

    if _has_cmd tldr; then
        alias manual='tldr'        # Quick command reference (tldr)
        alias help='tldr'          # Quick command reference (tldr)
        alias tldru='tldr --update'  # Update tldr cache
    fi

    if _has_cmd hyperfine; then
        alias bench='hyperfine'      # Benchmark command
        alias benchmark='hyperfine'  # Benchmark command
    fi

    _log DEBUG "Modern tool replacements configured"
fi

# ----------------------------------------------------------
# * AI
# ----------------------------------------------------------

if _has_cmd fabric-ai; then
    alias fabric='fabric-ai'  # Fabric AI client
fi

# ----------------------------------------------------------
# * HOMEBREW (macOS)
# ----------------------------------------------------------

if _has_cmd brew; then
    alias brewup='brew update && brew upgrade && brew cleanup'  # Update all
    alias brewclean='brew cleanup --prune=all && brew autoremove'  # Clean up
    alias brewdoctor='brew doctor'         # Check system
    alias brewdeps='brew deps --tree --installed'  # Show dependency tree
    alias brewleaves='brew leaves'         # Show packages with no dependents
    alias brewoutdated='brew outdated'     # Show outdated packages
fi

# ----------------------------------------------------------
# * DEVELOPMENT - PYTHON
# ----------------------------------------------------------

if _has_cmd python3; then
    alias py='python3'              # Python 3 interpreter
    alias python='python3'          # Python 3 interpreter
    alias venv='python3 -m venv'    # Create virtual environment
else
    alias py='python'               # Python interpreter
    alias venv='python -m venv'     # Create virtual environment
fi

if _has_cmd pip3; then
    alias pip='pip3'  # Python package manager
elif ! _has_cmd pip && _has_cmd python3; then
    alias pip='python3 -m pip'  # Python package manager
fi

alias activate='zsh_activate_venv'  # Activate nearest virtualenv

# ----------------------------------------------------------
# * DEVELOPMENT - NODE.JS
# ----------------------------------------------------------

if _has_cmd npm; then
    alias npi='npm install'                            # npm install dependencies
    alias npig='npm install --global'                  # npm install globally
    alias npid='npm install --save-dev'                # npm install as devDep
    alias nps='npm start'                              # npm start
    alias npt='npm test'                               # npm test
    alias npr='npm run'                                # npm run script
    alias npb='npm run build'                          # npm build
    alias npre='npm run eslint'                        # npm run eslint
    alias npref='npm run eslint --fix'                 # npm run eslint --fix
    alias npc='rm -rf node_modules package-lock.json'  # npm clean
fi

if _has_cmd yarn; then
    alias yai='yarn install'                           # yarn install dependencies
    alias yaig='yarn global add'                       # yarn install globally
    alias yaid='yarn add --dev'                        # yarn install as devDep
    alias yas='yarn start'                             # yarn start
    alias yat='yarn test'                              # yarn test
    alias yar='yarn run'                               # yarn run script
    alias yab='yarn build'                             # yarn build
    alias yare='yarn run eslint'                       # yarn run eslint
    alias yaref='yarn run eslint --fix'                # yarn run eslint --fix
    alias yac='rm -rf node_modules yarn.lock'          # yarn clean
fi

if _has_cmd pnpm; then
    alias pni='pnpm install'                           # pnpm install dependencies
    alias pnig='pnpm add --global'                     # pnpm install globally
    alias pnid='pnpm add --save-dev'                   # pnpm install as devDep
    alias pns='pnpm start'                             # pnpm start
    alias pnt='pnpm test'                              # pnpm test
    alias pnr='pnpm run'                               # pnpm run script
    alias pnb='pnpm build'                             # pnpm build
    alias pnre='pnpm run eslint'                       # pnpm run eslint
    alias pnref='pnpm run eslint --fix'                # pnpm run eslint --fix
    alias pnc='rm -rf node_modules pnpm-lock.yaml'     # pnpm clean
fi

# ----------------------------------------------------------
# * GIT (Intuitive First-Letter System)
# ? Pattern: g + first letter of each word
# ? Modifiers: a=all, s=staged, f=force, m=message
# ----------------------------------------------------------

if _has_cmd git; then
    # ─── STATUS & INFO ───
    alias gs='git status --short --branch'  # Git status (short)
    alias gss='git status'                  # Git status (full)
    alias gl='git log --oneline --decorate -20'  # Git log (20 commits)
    alias gla='git log --oneline --decorate --all -20'  # Git log all branches
    alias glg='git log --graph --oneline --decorate -20'  # Git log graph
    alias glga='git log --graph --oneline --decorate --all'  # Git log full graph
    alias gd='git diff'         # Git diff unstaged
    alias gds='git diff --staged'  # Git diff staged
    alias gsh='git show'        # Git show commit

    # ─── STAGING & COMMITS ───
    alias ga='git add'                   # Git add files
    alias gaa='git add --all'            # Git add all
    alias gap='git add --patch'          # Git add interactive
    alias gc='git commit'                # Git commit
    alias gcm='git commit -m'            # Git commit with message
    alias gca='git commit --amend'       # Git amend commit
    alias gcam='git commit --amend -m'   # Git amend with message
    alias gcan='git commit --amend --no-edit'  # Git amend no edit

    # ─── BRANCHES ───
    alias gb='git branch'          # Git list branches
    alias gba='git branch --all'   # Git list all branches
    alias gbd='git branch -d'      # Git delete branch (safe)
    alias gbD='git branch -D'      # Git delete branch (force)
    alias gco='git checkout'       # Git checkout
    alias gcb='git checkout -b'    # Git checkout new branch
    alias gsw='git switch'         # Git switch branch
    alias gswc='git switch -c'     # Git switch new branch

    # ─── REMOTE ───
    alias gf='git fetch'                  # Git fetch
    alias gfa='git fetch --all --prune'   # Git fetch all + prune
    alias gpl='git pull'                  # Git pull
    alias gplr='git pull --rebase'        # Git pull rebase
    alias gps='git push'                  # Git push
    alias gpsf='git push --force-with-lease'  # Git push force (safe)
    alias gpsu='git push -u origin HEAD'  # Git push set upstream

    # ─── MERGE & REBASE ───
    alias gm='git merge'               # Git merge
    alias gmom='git merge origin/main'  # Git merge origin/main
    alias grb='git rebase'             # Git rebase
    alias grbi='git rebase -i'         # Git rebase interactive
    alias grbm='git rebase main'       # Git rebase onto main
    alias grbc='git rebase --continue'  # Git rebase continue
    alias grba='git rebase --abort'    # Git rebase abort

    # ─── STASH ───
    alias gst='git stash'           # Git stash changes
    alias gstl='git stash list'     # Git stash list
    alias gstp='git stash pop'      # Git stash pop
    alias gsta='git stash apply'    # Git stash apply
    alias gstd='git stash drop'     # Git stash drop
    alias gstm='git stash push -m'  # Git stash with message

    # ─── UNDO & RESET ───
    alias grs='git restore'          # Git restore file
    alias grss='git restore --staged'  # Git unstage file
    alias grh='git reset HEAD'       # Git reset soft
    alias grhh='git reset --hard HEAD'  # Git reset hard
    alias gundo='git reset HEAD~1'   # Git undo last commit
    alias gclean='git clean -fd'     # Git clean untracked

    # ─── WORKTREE ───
    alias gwt='git worktree'        # Git worktree
    alias gwtl='git worktree list'  # Git worktree list
    alias gwta='git worktree add'   # Git worktree add
    alias gwtr='git worktree remove'  # Git worktree remove

    # ─── BISECT ───
    alias gbi='git bisect'        # Git bisect
    alias gbis='git bisect start'  # Git bisect start
    alias gbig='git bisect good'   # Git bisect good
    alias gbib='git bisect bad'    # Git bisect bad
    alias gbir='git bisect reset'  # Git bisect reset

    # ─── MISC ───
    alias gbl='git blame -w'                    # Git blame (ignore whitespace)
    alias gcl='git clone --recurse-submodules'  # Git clone with submodules
    alias gcp='git cherry-pick'                 # Git cherry-pick
    alias gt='git tag'                          # Git tag
    alias grm='git rm'                          # Git remove file
    alias gmv='git mv'                          # Git move/rename
    alias gcleanup='zsh_git_cleanup'            # Delete merged branches

    if _has_cmd lazygit; then
        alias lg='lazygit'  # Lazygit TUI
    fi
fi

# ----------------------------------------------------------
# * DOCKER
# ----------------------------------------------------------

if _has_cmd docker; then
    alias dc='docker-compose'             # Docker Compose
    alias dps='docker ps'                 # Docker list running
    alias dpsa='docker ps -a'             # Docker list all
    alias dimg='docker images'            # Docker list images
    alias dvol='docker volume ls'         # Docker list volumes
    alias dnet='docker network ls'        # Docker list networks
    alias dstop='zsh_docker_stop_all'  # Docker stop all containers
    alias dclean='read -k 1 "REPLY?Prune all stopped containers/images? [y/N] " && [[ $REPLY =~ ^[Yy]$ ]] && docker system prune -af'  # Docker prune everything
    alias drmi='zsh_docker_rmi_dangling'  # Docker remove dangling images
    alias drmv='zsh_docker_rmv_dangling'  # Docker remove dangling volumes

    if _has_cmd lazydocker; then
        alias lzd='lazydocker'      # Lazydocker TUI
        alias docker-ui='lazydocker'  # Lazydocker TUI
    fi
    if _has_cmd ctop; then
        alias docker-top='ctop'  # Container top
    fi
fi

# ----------------------------------------------------------
# * ANSIBLE
# ? Infrastructure automation
# ----------------------------------------------------------

if _has_cmd ansible; then
    alias ans='ansible'              # Ansible ad-hoc
    alias ansp='ansible-playbook'    # Ansible playbook
    alias ansi='ansible-inventory'   # Ansible inventory
    alias ansd='ansible-doc'         # Ansible docs
    alias ansg='ansible-galaxy'      # Ansible Galaxy
    alias ansv='ansible-vault'       # Ansible Vault
    alias ansc='ansible-config'      # Ansible config
fi

# ----------------------------------------------------------
# * CLIPBOARD UTILITIES
# ? OMZ copypath/copyfile plugins with shorter aliases
# ----------------------------------------------------------

if (( $+functions[copypath] )); then
    alias cpath='copypath'  # Copy current path to clipboard
fi
if (( $+functions[copyfile] )); then
    alias cfile='copyfile'  # Copy file contents to clipboard
fi

# ----------------------------------------------------------
# * SYSTEM & NETWORK
# ----------------------------------------------------------

if _is_macos || _is_bsd; then
    alias psg='ps aux | grep -v grep | grep -i'  # Search processes
else
    alias psg='ps auxf | grep -v grep | grep -i'  # Search processes
fi

alias pskill='zsh_pskill'    # Kill process by name
alias ka='killall'           # Kill all by name
alias timeout='zsh_timeout'  # Run command with time limit

alias ports='zsh_show_ports'    # Show listening ports
alias ip='zsh_publicip'         # Show public IP
alias localip='zsh_localip'     # Show local IP
alias speedtest='zsh_speedtest'  # Test internet speed
alias portcheck='zsh_portcheck'  # Check if port is open
alias waitport='zsh_waitport'    # Wait for port to open
alias p8='ping -c 5 8.8.8.8'    # Quick connectivity test

if (( $+aliases[top] )) && [[ "${aliases[top]}" == *btm* ]]; then
    alias cpu='btm'  # CPU monitor
    alias mem='btm'  # Memory monitor
elif _is_macos; then
    alias cpu='top -o cpu'    # CPU monitor
    alias mem='top -o rsize'  # Memory monitor
elif _has_cmd top; then
    alias cpu='top'  # CPU monitor
    alias mem='top'  # Memory monitor
fi

# ----------------------------------------------------------
# * MACOS SPECIFIC
# ? Platform-specific aliases for macOS only
# ----------------------------------------------------------

if _is_macos; then
    # Finder
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'   # Show hidden files
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'  # Hide hidden files
    alias o='open'                       # Open file/folder
    alias o.='open .'                    # Open current directory
    alias ql='qlmanage -p 2>/dev/null'   # Quick Look preview

    # System
    alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'  # Flush DNS cache
    alias lock='pmset displaysleepnow'   # Lock screen
    alias afk='open -a ScreenSaverEngine'  # Start screensaver
    alias killapp='zsh_killapp'          # Kill app by name

    # Clipboard
    alias pbp='pbpaste'   # Paste from clipboard
    alias pbc='pbcopy'    # Copy to clipboard

    # WiFi & Disk
    alias wifi-scan='airport -s'   # Scan WiFi networks
    alias wifi-info='airport -I'   # WiFi connection info
    alias wifi-name='zsh_wifi_name'       # Current WiFi name
    alias wifi-pass='zsh_wifi_password'   # WiFi password
    alias eject='diskutil eject'   # Eject disk

    # Utilities
    alias check-tools='zsh_macos_check_tools'  # Check recommended tools
fi

# ----------------------------------------------------------
# * LINUX SPECIFIC
# ? Platform-specific aliases for Linux only
# ----------------------------------------------------------

if _is_linux; then
    # Package managers (distro-specific)
    if _has_cmd apt; then
        alias aptu='sudo apt update && sudo apt upgrade -y'  # Update all
        alias aptc='sudo apt autoremove -y && sudo apt autoclean'  # Clean up
        alias apts='apt-cache search'  # Search packages
        alias apti='apt-cache show'      # Package info
    elif _has_cmd dnf; then
        alias dnfu='sudo dnf upgrade -y'   # Update all
        alias dnfc='sudo dnf autoremove -y && sudo dnf clean all'  # Clean up
    elif _has_cmd pacman; then
        alias pacu='sudo pacman -Syu'      # Update all
        alias pacc='sudo pacman -Sc'    # Clean cache
        alias pacs='pacman -Ss'        # Search packages
        _has_cmd yay && alias yayu='yay -Syu'    # AUR update
        _has_cmd paru && alias paru='paru -Syu'  # AUR update
    fi

    # Systemd
    if _has_cmd systemctl; then
        alias sc='systemctl'                 # Systemctl
        alias scu='systemctl --user'         # User services
        alias scstart='sudo systemctl start'    # Start service
        alias scstop='sudo systemctl stop'      # Stop service
        alias screstart='sudo systemctl restart'  # Restart service
        alias scstatus='systemctl status'    # Service status
        alias scenable='sudo systemctl enable'   # Enable service
        alias scdisable='sudo systemctl disable' # Disable service
    fi

    # Journalctl
    if _has_cmd journalctl; then
        alias jctl='journalctl'              # Journal
        alias jctlf='journalctl -f'          # Follow journal
        alias jctlu='journalctl --user'      # User journal
        alias jctlb='journalctl -b'          # Boot journal
    fi

    # NetworkManager
    if _has_cmd nmcli; then
        alias wifi='nmcli device wifi'       # WiFi status
        alias wifils='nmcli device wifi list'  # List networks
        alias wificon='nmcli device wifi connect'  # Connect
        alias wifioff='nmcli radio wifi off'   # Disable WiFi
        alias wifion='nmcli radio wifi on'     # Enable WiFi
    fi

    # Utilities
    alias check-tools='zsh_linux_check_tools'  # Check recommended tools

    # WSL (Windows Subsystem for Linux)
    if _is_wsl; then
        alias explorer='explorer.exe'        # Windows Explorer
        alias wsl-open='wslview'             # Open in Windows
    fi
fi

# ----------------------------------------------------------
# * PRODUCTIVITY
# ----------------------------------------------------------

alias zshrc='${EDITOR:-vi} "${ZDOTDIR}/.zshrc"'           # Edit .zshrc
alias zshenv='${EDITOR:-vi} "${ZDOTDIR}/.zshenv"'         # Edit .zshenv
alias zlocal='${EDITOR:-vi} "${ZDOTDIR}/local.zsh"'       # Edit local.zsh
alias gitconfig='${EDITOR:-vi} "${XDG_CONFIG_HOME}/git/config"'  # Edit git config

alias e='${EDITOR:-vi}'         # Open in editor
alias et='${TERMINAL_EDITOR:-vi}'  # Open in terminal editor

alias reload='exec zsh'                          # Restart shell
alias src='source "${ZDOTDIR}/.zshrc"'           # Reload .zshrc

# ─── ZSH CONFIG UPDATE ───
alias zupdate='zsh_update'     # Update ZSH config to latest
alias zversion='zsh_version'   # Show ZSH config version
alias zcheck='${ZDOTDIR}/install.sh --check'  # Verify installation

alias now='date +"%Y-%m-%d %H:%M:%S"'  # Current datetime
alias nowdate='date +"%Y-%m-%d"'       # Current date
alias nowtime='date +"%H:%M:%S"'       # Current time
alias week='date +%V'                  # Current week number

alias calc='noglob zsh_calc'  # Calculator (noglob prevents * expansion)
alias weather='zsh_weather'  # Weather forecast

# ─── UTILITIES ───
alias uuid='uuidgen | tr "[:upper:]" "[:lower:]"'  # Generate lowercase UUID
alias timestamp='date +%s'     # Unix timestamp
alias isodate='date -u +"%Y-%m-%dT%H:%M:%SZ"'  # ISO 8601 UTC date

# ─── QUICK EDITS ───
alias hosts='sudo ${EDITOR:-vi} /etc/hosts'  # Edit hosts file
alias sshconfig='${EDITOR:-vi} ~/.ssh/config'  # Edit SSH config

# ----------------------------------------------------------
# * SUFFIX ALIASES
# ? Auto-open files by extension
# ----------------------------------------------------------

if [[ -n "${EDITOR}" ]] || _has_cmd vim || _has_cmd vi; then
    local suffix_editor="${EDITOR:-vi}"
    alias -s {txt,md,markdown,rst}="$suffix_editor"
    alias -s {json,yml,yaml,toml,ini,conf,cfg}="$suffix_editor"
    alias -s {py,js,ts,jsx,tsx,go,rs,java,c,cpp,h,hpp}="$suffix_editor"
    alias -s {html,htm,css,scss,sass}="$suffix_editor"
fi

if ! _has_cmd extract; then
    _has_cmd tar && alias -s {tar,gz,bz2,xz}='tar -tf'
    _has_cmd unzip && alias -s zip='unzip -l'
    _has_cmd 7z && alias -s 7z='7z l'
    if _has_cmd unrar; then
        alias -s rar='unrar l'
    elif _has_cmd 7z; then
        alias -s rar='7z l'
    fi
fi

# ----------------------------------------------------------
# * GLOBAL ALIASES
# ? Expand anywhere in command line
# ----------------------------------------------------------

alias -g G='| grep'   # Pipe to grep
alias -g L='| less'   # Pipe to less
alias -g H='| head'   # Pipe to head
alias -g T='| tail'   # Pipe to tail
alias -g S='| sort'   # Pipe to sort
alias -g U='| uniq'   # Pipe to uniq
alias -g C='| wc -l'  # Count lines
alias -g F='| fzf'    # Pipe to fzf

alias -g NE='2>/dev/null'     # Suppress errors
alias -g NUL='>/dev/null 2>&1'  # Suppress all output
alias -g ERR='2>&1'           # Redirect stderr to stdout

if _has_cmd jq; then
    alias -g JQ='| jq'    # Pipe to jq
    alias -g JQC='| jq -C'  # Pipe to jq (color)
    alias -g JQR='| jq -r'  # Pipe to jq (raw)
fi

# ----------------------------------------------------------
# * LAZY LOADING STATUS
# ----------------------------------------------------------

alias lazy='zsh_lazy_status'   # Show lazy loading status

# ----------------------------------------------------------
# * INTROSPECTION
# ? Interactive alias browser with fzf TUI (includes search)
# ----------------------------------------------------------

alias als='zsh_alias_browser'      # Interactive alias browser
alias aliases='zsh_alias_browser'  # Interactive alias browser

# ----------------------------------------------------------
_log DEBUG "ZSH Aliases Module loaded successfully"
