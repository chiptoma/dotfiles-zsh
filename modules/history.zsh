#!/usr/bin/env zsh
# ==============================================================================
# * ZSH HISTORY MODULE
# ? Advanced history management with security filtering and search.
# ? Provides backup, cleanup, stats, and interactive search via fzf.
# ==============================================================================

# ----------------------------------------------------------
# * MODULE CONFIGURATION
# ----------------------------------------------------------

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_HISTORY_LOADED} )) && return 0
typeset -g _ZSH_HISTORY_LOADED=1

# Configuration variables with defaults
: ${ZSH_HISTORY_ENABLED:=true}          # Enable/disable history system
: ${ZSH_HISTORY_SIZE:=100000}           # Commands to keep in memory
: ${ZSH_HISTORY_SAVE_SIZE:=100000}      # Commands to save to file
: ${ZSH_HISTORY_SECURITY_FILTER:=true}  # Filter sensitive commands
: ${ZSH_HISTORY_LARGE_FILE_THRESHOLD:=500000}  # Lines before showing "large file" warning

_log DEBUG "ZSH History Module loading"

# Exit early if history is disabled
if [[ "$ZSH_HISTORY_ENABLED" != "true" ]]; then
    _log INFO "ZSH History Module disabled, skipping..."
    return 0
fi

# ----------------------------------------------------------
# * SHELL OPTIONS
# ? History-related shell behavior settings
# ----------------------------------------------------------

setopt APPEND_HISTORY          # Append history to file instead of overwriting
setopt SHARE_HISTORY           # Share history between terminal sessions
setopt HIST_IGNORE_ALL_DUPS    # Ignore duplicate commands
setopt HIST_IGNORE_SPACE       # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks
setopt EXTENDED_HISTORY        # Save timestamp of command and duration
setopt HIST_VERIFY             # Show command with history expansion before running it
setopt HIST_FIND_NO_DUPS       # Don't display duplicates when searching
setopt HIST_SAVE_NO_DUPS       # Don't write duplicate entries to history file

# ----------------------------------------------------------
# * HISTORY STORAGE
# ? Configure history file location and size
# ----------------------------------------------------------

export ZSH_HISTORY_DIR="${ZSH_STATE_HOME}/history"
export HISTFILE="${ZSH_HISTORY_DIR}/plain"
export HISTSIZE="$ZSH_HISTORY_SIZE"
export SAVEHIST="$ZSH_HISTORY_SAVE_SIZE"

_log DEBUG "Configuring history storage..."

# Ensure the history directory exists with correct permissions
_ensure_dir "$ZSH_HISTORY_DIR" 700

# Ensure the history file exists with correct permissions
if [[ -f "$HISTFILE" ]]; then
    chmod 600 "$HISTFILE" 2>/dev/null
else
    touch "$HISTFILE" 2>/dev/null && chmod 600 "$HISTFILE" 2>/dev/null
fi

# ----------------------------------------------------------
# * SECURITY FILTER PATTERNS
# ? Commands matching these patterns are excluded from history
# ----------------------------------------------------------

typeset -gra ZSH_HISTORY_IGNORE_PATTERNS=(
  # Secrets with assignment context (more specific to avoid false positives)
  '*=*api_key*'
  '*=*apikey*'
  '*=*password*'
  '*=*passwd*'
  '*=*secret*'
  '*=*private_key*'
  '*=*credential*'
  '*=*access_token*'

  # Environment variable exports with sensitive values
  'export *KEY=*'
  'export *SECRET=*'
  'export *TOKEN=*'
  'export *PASS=*'
  'export *PASSWORD=*'
  'export *CREDENTIAL=*'
  'export AWS_*'

  # Password managers & secret tooling (command prefixes)
  'op *'             # 1Password CLI
  'bw *'             # Bitwarden CLI
  'pass *'           # Standard Unix password manager
  'gopass *'         # Go-based pass fork
  'vault *'          # Hashicorp Vault
  'sops *'           # Mozilla SOPS
  'keychain *'       # SSH/GPG agent helper

  # GPG operations with sensitive flags
  'gpg --decrypt*'
  'gpg -d *'
  'gpg --import*'
  'gpg --passphrase*'

  # SSH with embedded passwords
  'sshpass *'
  '*sshpass*'

  # Cloud auth commands
  'gcloud auth *'
  'az login *'
  'doctl auth *'
  'aws configure *'

  # Docker secrets
  'docker login *'
  'docker secret *'

  # HTTP requests with credentials
  'curl *--user *'
  'curl *--header*[Aa]uthorization*'
  'curl *-u *:*'
  'curl *-H *[Aa]uthorization*'
  'wget *--http-user*'
  'wget *--password*'

  # Git with embedded credentials
  'git clone *://*:*@*'
  'git push *://*:*@*'
  'git pull *://*:*@*'
  'gh auth login*'

  # Files containing secrets
  '*secrets.yaml*'
  '*secrets.env*'
  '*.credentials*'
)

# ----------------------------------------------------------
# * HELPER FUNCTIONS
# ? Internal utilities for history management
# ----------------------------------------------------------

_should_ignore_history_cmd() {
  local cmd="$1"
  [[ -z "$cmd" ]] && return 1

  local pattern
  for pattern in "${ZSH_HISTORY_IGNORE_PATTERNS[@]}"; do
    if [[ "$cmd" == ${~pattern} ]]; then
      return 0  # Matches pattern - should be ignored
    fi
  done

  return 1  # No match - should be recorded
}

# Helper function to create a history file backup
_create_history_backup() {
    local backup_file_path="$1"
    if [[ -z "$backup_file_path" ]]; then
        echo "Error: No backup path provided." >&2
        return 1
    fi
    if ! cp "$HISTFILE" "$backup_file_path"; then
        echo "Error: Failed to create backup at '$backup_file_path'." >&2
        return 1
    fi
    # Secure the backup file (history may contain sensitive commands)
    chmod 600 "$backup_file_path" 2>/dev/null
    return 0
}

# Widget wrapper for history_search_interactive
_history_search_interactive_widget() {
    # Save and clear current buffer
    local saved_buffer="$BUFFER"
    BUFFER=""

    # Temporarily redirect to call the function
    zle -I
    {
        history_search_interactive
    } </dev/tty

    # If nothing was selected and we had a saved buffer, restore it
    if [[ -z "$BUFFER" && -n "$saved_buffer" ]]; then
        BUFFER="$saved_buffer"
    fi

    zle redisplay
}

# ----------------------------------------------------------
# * PUBLIC FUNCTIONS
# ? User-facing history management commands
# ----------------------------------------------------------

history_backup() {
    # Check if HISTFILE exists and is a readable file
    if [[ ! -f "$HISTFILE" || ! -r "$HISTFILE" ]]; then
        echo "Error: History file ($HISTFILE) not found or not readable." >&2
        return 1
    fi

    # Determine backup base name (e.g., "plain.backup" or user-provided)
    local base_histfile_name="${HISTFILE:t}" # Basename of HISTFILE, e.g., "plain"
    local backup_base_name="${1:-${base_histfile_name}.backup}"

    # Determine backup directory interactively
    local default_backup_dir="${ZSH_DATA_HOME}/backups/history"
    local target_backup_dir
    local response custom_dir create_q  # Declare locals for vared

    echo "Default backup directory is: ${default_backup_dir}"
    vared -c -p "Use this directory? (y/n): " response

    if [[ "$response" == "n" || "$response" == "N" ]]; then
        vared -c -p "Enter custom backup directory path: " custom_dir
        # Expand tilde, handle empty input
        custom_dir="${custom_dir/#\~/$HOME}"
        if [[ -z "$custom_dir" ]]; then
            echo "No custom directory provided, exiting." >&2
            return 1
        fi
        target_backup_dir="$custom_dir"
    else
        target_backup_dir="$default_backup_dir"
    fi

    # Ensure target backup directory exists and is writable
    if [[ ! -d "$target_backup_dir" ]]; then
        echo "Target directory '$target_backup_dir' does not exist."
        vared -c -p "Create it? (y/n): " create_q
        if [[ "$create_q" == "y" || "$create_q" == "Y" ]]; then
            if ! mkdir -p "$target_backup_dir"; then
                echo "Error: Failed to create directory '$target_backup_dir', exiting." >&2
                return 1
            fi
            echo "Directory '$target_backup_dir' created."
        else
            echo "Directory not created, exiting." >&2
            return 1
        fi
    fi

    if [[ ! -w "$target_backup_dir" ]]; then
        echo "Error: Target directory '$target_backup_dir' is not writable, exiting." >&2
        return 1
    fi

    # Construct final backup file path
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local final_backup_filename="${backup_base_name}_${timestamp}.txt"
    local backup_file_path="${target_backup_dir}/${final_backup_filename}"

    # Perform the backup by calling the core function
    if _create_history_backup "$backup_file_path"; then
        echo "✓ History file backed up to: $backup_file_path"
        return 0
    else
        # Error is printed by the core function
        return 1
    fi
}

# Public function to clean history by removing duplicates and sensitive commands.
history_clean() {
    if [[ ! -f "$HISTFILE" || ! -r "$HISTFILE" ]]; then
        echo "Error: History file ($HISTFILE) not found or not readable." >&2
        return 1
    fi

    # Prevent concurrent access from multiple shells
    local lock_dir="${HISTFILE}.lock"

    # Check for stale lock (older than 1 hour = 3600 seconds)
    if [[ -d "$lock_dir" ]]; then
        local lock_age=0
        local lock_mtime
        if _is_macos; then
            lock_mtime=$(stat -f %m "$lock_dir" 2>/dev/null || echo 0)
        else
            lock_mtime=$(stat -c %Y "$lock_dir" 2>/dev/null || echo 0)
        fi
        if [[ "$lock_mtime" -gt 0 ]]; then
            lock_age=$(( EPOCHSECONDS - lock_mtime ))
        fi

        if (( lock_age > 3600 )); then
            echo "Warning: Removing stale lock (${lock_age}s old)" >&2
            rmdir "$lock_dir" 2>/dev/null
        fi
    fi

    if ! mkdir "$lock_dir" 2>/dev/null; then
        echo "Error: History file is locked by another process." >&2
        echo "If you're sure no other process is cleaning history, remove: $lock_dir" >&2
        return 1
    fi

    # ? Preserve existing traps before setting cleanup trap
    local _old_trap_exit _old_trap_int _old_trap_term
    _old_trap_exit=$(trap -p EXIT 2>/dev/null)
    _old_trap_int=$(trap -p INT 2>/dev/null)
    _old_trap_term=$(trap -p TERM 2>/dev/null)

    # Clean up lock on exit and restore previous traps
    trap "rmdir '$lock_dir' 2>/dev/null; ${_old_trap_exit:+eval \"\${_old_trap_exit#trap -- }\"}" EXIT
    trap "rmdir '$lock_dir' 2>/dev/null; ${_old_trap_int:+eval \"\${_old_trap_int#trap -- }\"}" INT
    trap "rmdir '$lock_dir' 2>/dev/null; ${_old_trap_term:+eval \"\${_old_trap_term#trap -- }\"}" TERM

    local temp_file="${HISTFILE}.tmp"
    local backup_dir="${ZSH_DATA_HOME}/backups/history"
    local temp_backup_file="${backup_dir}/pre-clean-temp_$(date +%Y%m%d_%H%M%S).bak"

    # Ensure backup directory exists
    _ensure_dir "$backup_dir"

    # 1. Get original line count
    local -i original_lines
    original_lines=$(wc -l < "$HISTFILE")

    # Warn about large history files (may take a moment)
    if (( original_lines > ZSH_HISTORY_LARGE_FILE_THRESHOLD )); then
        print -P "%F{yellow}Warning:%f Large history file ($original_lines lines). This may take a moment..."
    fi

    # 2. Create a temporary backup using the core function
    if ! _create_history_backup "$temp_backup_file"; then
        echo "Aborting clean." >&2
        return 1
    fi

    # 3. Build a single regex for awk from ZSH_HISTORY_IGNORE_PATTERNS
    local awk_patterns=()
    local pattern
    for pattern in "${ZSH_HISTORY_IGNORE_PATTERNS[@]}"; do
        # Convert zsh glob patterns to awk-compatible extended regex
        # This is a basic conversion; it changes '*' to '.*'
        awk_patterns+=( "${pattern//\*/.*}" )
    done
    local full_awk_pattern
    # Use Zsh parameter expansion to join array elements with '|'
    full_awk_pattern="${(j.|.)awk_patterns}"

    # 4. Process history: remove duplicates and sensitive commands using the generated pattern.
    # This awk script handles the EXTENDED_HISTORY format (': <ts>:<dur>;<cmd>')
    # It extracts the command part for filtering and uniqueness checks.
    # LC_ALL=C is used to prevent errors with multi-byte characters.
    # Keep only the last occurrence of each command, output in chronological order.
    LC_ALL=C awk -v pattern="$full_awk_pattern" '
        BEGIN { FS=OFS=";" }
        {
            # Extract command part after the first semicolon
            cmd = substr($0, index($0, ";") + 1)
            # Skip if it matches the sensitive pattern
            if (cmd !~ pattern) {
                # Store the line, overwriting any previous occurrence of the same command
                lines[cmd] = $0
                # Track the last line number where this command appeared
                last_seen[cmd] = NR
                # Store all lines for iteration in END block
                all_lines[NR] = $0
                all_cmds[NR] = cmd
            }
        }
        END {
            # Output lines in chronological order, but only at their last occurrence
            for (i = 1; i <= NR; i++) {
                if (i in all_cmds) {
                    cmd = all_cmds[i]
                    # Only print if this is the last occurrence of this command
                    if (i == last_seen[cmd]) {
                        print lines[cmd]
                    }
                }
            }
        }
    ' "$HISTFILE" > "$temp_file"

    # 5. Check result: if cleaned file is valid, replace original and delete backup.
    #    If not, restore from backup and report failure.
    if [[ -s "$temp_file" ]]; then
        # Success: Calculate the number of lines removed
        local -i new_lines
        new_lines=$(wc -l < "$temp_file")

        local -i lines_removed=$((original_lines - new_lines))

        mv "$temp_file" "$HISTFILE"
        rm -f "$temp_backup_file"
        fc -R "$HISTFILE" # Reload history into the current session

        echo "✓ History cleaned successfully, removed $lines_removed lines."

        return 0
    else
        # Failure
        echo "Error: History cleaning failed (cleaned file was empty)."
        echo "Restoring history from temporary backup..."
        # Restore by moving the backup file back into place.
        if mv "$temp_backup_file" "$HISTFILE"; then
            echo "History restored successfully."
        else
            echo "CRITICAL ERROR: Failed to restore history from '$temp_backup_file'."
            echo "Your original history is safe at that location. Please restore it manually." >&2
        fi
        # Clean up other temp file
        rm -f "$temp_file"
        return 1
    fi
}

# Public function to show history statistics
history_stats() {
    local top_n="$1"

    if [[ ! -f "$HISTFILE" || ! -r "$HISTFILE" ]]; then
        echo "History file not found or not readable: $HISTFILE" >&2
        return 1
    fi
    if ! _has_cmd awk; then
        echo "awk command not found, cannot generate stats." >&2
        return 1
    fi

    if [[ -n "$top_n" ]]; then
        echo "Top $top_n commands from history:"
    else
        echo "All commands from history (sorted by frequency):"
    fi
    # Read history file directly and process
    # for EXTENDED_HISTORY format: ': <timestamp>:<duration>;<command>'
    awk -F';' '
        {
            # Extract command part after the first semicolon
            if (NF >= 2) {
                cmd = substr($0, index($0, ";") + 1)
                # Get just the command name (first word)
                split(cmd, parts, " ")
                if (parts[1] != "") {
                    CMD[parts[1]]++
                }
            }
        }
        END {
            for (cmd in CMD) {
                printf "%d %s\n", CMD[cmd], cmd
            }
        }
    ' "$HISTFILE" | \
        LC_ALL=C sort -rn | \
        { if [[ -n "$top_n" ]]; then head -n "$top_n"; else cat; fi } | \
        awk '
            !max {max=$1; if (max==0) max=1}
            {
                # Calculate dynamic width for command column
                cmd_width = 25
                bar_width = 50
                count = $1
                cmd = $2

                # Calculate bar length proportional to max
                bar_len = int(count * bar_width / max)

                # Print command name, then bar with count
                printf "%-*s ", cmd_width, cmd

                # Print the bar with count inside
                count_str = sprintf("[%d]", count)
                count_len = length(count_str)

                # Print count at the beginning of the bar
                printf "%s", count_str

                # Fill the rest with bar characters
                for(i=count_len+1; i<=bar_len; i++) printf "█"

                print ""
            }'
}

# Public function for interactive history search with fzf
history_search_interactive() {
    # Check if fzf is available
    if ! _has_cmd fzf; then
        echo "Error: fzf is not installed. Install it with: brew install fzf" >&2
        return 1
    fi

    if [[ ! -f "$HISTFILE" || ! -r "$HISTFILE" ]]; then
        echo "Error: History file ($HISTFILE) not found or not readable." >&2
        return 1
    fi

    local selected

    # Use utility function for clipboard detection (avoids code duplication)
    local clip_cmd
    clip_cmd="$(_get_clipboard_cmd)"

    # Extract commands from history, remove duplicates (keeping last occurrence)
    # and present them in fzf for interactive search
    selected=$(awk -F';' '
        {
            # Extract command part after the first semicolon
            if (NF >= 2) {
                cmd = substr($0, index($0, ";") + 1)
                # Store commands, overwriting duplicates to keep last occurrence
                cmds[cmd] = NR
            }
        }
        END {
            # Sort by line number and output commands
            for (cmd in cmds) {
                print cmds[cmd], cmd
            }
        }
    ' "$HISTFILE" | \
    LC_ALL=C sort -n | \
    LC_ALL=C cut -d' ' -f2- | \
    fzf --tac \
        --no-sort \
        --query="$1" \
        --height=50% \
        --layout=reverse \
        --border=rounded \
        --prompt="🔍 Search history: " \
        --header=$'\n' \
        --info=inline \
        --color="fg:#abb2bf,bg:-1,hl:#98c379,fg+:#abb2bf,bg+:#2c323c,hl+:#98c379,info:#e5c07b,prompt:#c678dd,pointer:#61afef,marker:#e5c07b,spinner:#e5c07b,header:#e06c75" \
        --preview="echo '🖥️ Command preview:'; echo; echo {}" \
        --preview-window="down:5:wrap" \
        --border-label="┤ ⏎ select · ^Y copy · ^/ preview ├" \
        --border-label-pos="bottom" \
        --margin=1 \
        --padding=1 \
        --pointer="▶" \
        --marker="✓" \
        --ansi \
        --bind="ctrl-y:execute-silent(echo -n {} | $clip_cmd)+abort" \
        --bind="ctrl-/:toggle-preview" \
        --bind="ctrl-l:clear-query")

    if [[ -n "$selected" ]]; then
        # Put the selected command into the ZLE buffer
        print -z "$selected"
    fi
}

# ----------------------------------------------------------
# * ZSH HOOKS
# ? Hook into ZSH history system for security filtering
# ----------------------------------------------------------

function zshaddhistory() {
  # Strip trailing newline and all leading/trailing whitespace
  local cmd="${${1%%$'\n'}##[[:space:]]#}"
  cmd="${cmd%%[[:space:]]#}"

  # Only filter if security filter is enabled
  if [[ "$ZSH_HISTORY_SECURITY_FILTER" == "true" ]]; then
    _should_ignore_history_cmd "$cmd" && return 1
  fi

  return 0
}

# FZF-specific features (only if fzf is available)
if _has_cmd fzf; then
    # Create the widget for interactive history search
    zle -N _history_search_interactive_widget

    # Bind CTRL-R to fzf history search ONLY if atuin is not available
    # (atuin binds ^R in lazy.zsh and takes priority when installed)
    if ! _has_cmd atuin; then
        bindkey '^R' _history_search_interactive_widget
    fi

    # FZF-powered alias (always available alongside atuin)
    alias h="history_search_interactive"  # Interactive history search (fzf)
else
    # ? fzf not installed - provide useful fallback with clear message
    _log WARN "fzf not installed - history search limited. Install: brew install fzf"
    alias h="history -100"                # Fallback: show last 100 commands
    # ? Alternative aliases still work: hl (pager), hs (grep)
fi

# ----------------------------------------------------------
# * ALIASES
# ? Convenient shortcuts for history operations
# ----------------------------------------------------------

# History search and display (non-fzf)
alias hh="history"                    # Show raw history output
alias hl="history | less"             # Show history with less
alias hs="history | grep"             # Show history with grep

# History management
alias hbackup="history_backup"        # Backup history file
alias hclean="history_clean"          # Clean history file
alias hstats="history_stats"          # Show history statistics

# ----------------------------------------------------------
_log DEBUG "ZSH History Module loaded"
