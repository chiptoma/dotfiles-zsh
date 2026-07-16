#!/usr/bin/env zsh
# ==============================================================================
# XDG GUARDIAN
# Self-healing XDG compliance. Detects stray dotfiles in $HOME, migrates to
# XDG locations with atomic backup/restore, detects orphaned XDG directories.
# Uses xdg-ninja database (629 programs) with fallback to our registry.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_XDG_GUARDIAN_LOADED} )) && return 0
typeset -g _Z_XDG_GUARDIAN_LOADED=1

# Configuration variables with defaults
: ${Z_XDG_GUARDIAN_ENABLED:=true}
: ${Z_XDG_GUARDIAN_INTERVAL:=86400}
: ${Z_XDG_GUARDIAN_AUTO_FIX:=${Z_XDG_AUTO_MIGRATE:-false}}
: ${Z_XDG_GUARDIAN_QUIET:=false}
: ${Z_XDG_GUARDIAN_SKIP:=""}

# Exit early if disabled
[[ "$Z_XDG_GUARDIAN_ENABLED" != "true" ]] && return 0

# Load persisted skip list (must be after helpers are defined,
# but we need _xdg_load_skip_list early — define inline here)
{
    local _sf="${ZSH_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/zsh}/xdg-guardian.skip"
    if [[ -f "$_sf" ]]; then
        local _line
        while IFS= read -r _line; do
            [[ -z "$_line" ]] && continue
            [[ -n "$Z_XDG_GUARDIAN_SKIP" ]] && Z_XDG_GUARDIAN_SKIP="$Z_XDG_GUARDIAN_SKIP $_line" || Z_XDG_GUARDIAN_SKIP="$_line"
        done < "$_sf"
    fi
}

# Paths that must never be migrated
typeset -ga _Z_XDG_DEFAULT_SKIP=(
    '$HOME/.zshenv'
    '$HOME/.ssh'
    '$HOME/.Trash'
    '$HOME/.DS_Store'
    '$HOME/.trash'
)

# ----------------------------------------------------------
# INTERNAL HELPERS
# ----------------------------------------------------------

_xdg_ninja_db_path() {
    local dir
    for dir in \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/xdg-ninja/programs" \
        "/usr/local/share/xdg-ninja/programs" \
        "/usr/share/xdg-ninja/programs"; do
        if [[ -d "$dir" ]] && ls "$dir"/*.json &>/dev/null; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

_xdg_is_skipped() {
    local check_path="$1"
    local skip_path
    for skip_path in "${_Z_XDG_DEFAULT_SKIP[@]}" ${(s: :)Z_XDG_GUARDIAN_SKIP}; do
        [[ "${(e)skip_path}" == "$check_path" ]] && return 0
    done
    return 1
}

_xdg_format_size() {
    local kb="$1"
    if (( kb >= 1048576 )); then
        printf "%.1f GB" "$(( kb / 1048576.0 ))"
    elif (( kb >= 1024 )); then
        printf "%.1f MB" "$(( kb / 1024.0 ))"
    else
        printf "%d KB" "$kb"
    fi
}

_xdg_format_date() {
    local epoch="$1"
    if (( epoch > 0 )); then
        date -r "$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

_xdg_format_date_short() {
    local epoch="$1"
    if (( epoch > 0 )); then
        date -r "$epoch" '+%Y-%m-%d' 2>/dev/null || date -d "@$epoch" '+%Y-%m-%d' 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

_xdg_format_relative_time() {
    local epoch="$1"
    local now="${EPOCHSECONDS:-$(date +%s)}"
    local diff=$(( now - epoch ))

    if (( diff < 60 )); then
        echo "just now"
    elif (( diff < 3600 )); then
        echo "$(( diff / 60 )) minutes ago"
    elif (( diff < 86400 )); then
        echo "$(( diff / 3600 )) hours ago"
    elif (( diff < 2592000 )); then
        echo "$(( diff / 86400 )) days ago"
    else
        echo "$(( diff / 2592000 )) months ago"
    fi
}

_xdg_state_dir() {
    echo "${ZSH_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/zsh}"
}

# Add a path to the permanent skip list
_xdg_skip_permanently() {
    local path="$1"
    if [[ -n "$Z_XDG_GUARDIAN_SKIP" ]]; then
        Z_XDG_GUARDIAN_SKIP="$Z_XDG_GUARDIAN_SKIP $path"
    else
        Z_XDG_GUARDIAN_SKIP="$path"
    fi
    # Persist to state file so it survives shell restarts
    local state_dir
    state_dir=$(_xdg_state_dir)
    _ensure_dir "$state_dir"
    echo "$path" >> "$state_dir/xdg-guardian.skip"
}

# Extract human-friendly tool name from stray path
# ~/.ansible → ansible, ~/.cups → cups, ~/.docker → docker
_xdg_tool_name() {
    local name="${1##*/}"
    echo "${name#.}"
}

# Get item count for a path
_xdg_item_count() {
    if [[ -d "$1" ]]; then
        ls -A "$1" 2>/dev/null | wc -l | tr -d ' '
    else
        echo "1"
    fi
}

# Get size in KB for a path
_xdg_size_kb() {
    local sz
    sz=$(command du -sk "$1" 2>/dev/null | cut -f1)
    echo "${sz:-0}"
}

# ----------------------------------------------------------
# SCANNING
# ----------------------------------------------------------

# Shared findings array — populated by scan functions, read by callers.
# Key=expanded stray path, Value=pipe-delimited metadata.
# Callers must declare: typeset -gA _Z_XDG_FINDINGS=()

_xdg_scan_ninja() {
    local ninja_dir
    ninja_dir=$(_xdg_ninja_db_path) || return 1
    _has_cmd jq || return 1

    local json_file program stray_path movable help_line expanded
    for json_file in "$ninja_dir"/*.json(N); do
        while IFS=$'\t' read -r program stray_path movable help_line; do
            [[ -z "$stray_path" ]] && continue
            expanded="${stray_path/\$HOME/$HOME}"
            _xdg_is_skipped "$expanded" && continue
            [[ ! -e "$expanded" ]] && continue
            _Z_XDG_FINDINGS[$expanded]="${help_line}|${movable}|${program}|ninja"
        done < <(jq -r '.name as $n | .files[] | [$n, .path, (.movable | tostring), ((.help // "") | split("\n") | .[0])] | @tsv' "$json_file" 2>/dev/null)
    done
    return 0
}

# Scan our registry Z_XDG_MIGRATIONS for stray dotfiles
# No tool-existence gate: stray path existing IS the evidence
_xdg_scan_registry() {
    local stray_key val_str expanded_stray target rest hint movable command post_action expanded_target
    for stray_key val_str in ${(kv)Z_XDG_MIGRATIONS}; do
        expanded_stray="${(e)stray_key}"
        # Parse: target|hint|movable|command[|post_action]
        target="${val_str%%|*}"
        rest="${val_str#*|}"
        hint="${rest%%|*}"
        rest="${rest#*|}"
        movable="${rest%%|*}"
        rest="${rest#*|}"
        # command may contain post_action after another pipe
        command="${rest%%|*}"
        post_action="${rest#*|}"
        [[ "$post_action" == "$command" ]] && post_action=""

        _xdg_is_skipped "$expanded_stray" && continue
        [[ ! -e "$expanded_stray" ]] && continue

        expanded_target="${(e)target}"
        # Registry is authoritative — overwrites ninja entries
        _Z_XDG_FINDINGS[$expanded_stray]="${expanded_target}|${hint}|${movable}|${command}|${post_action}|managed"
    done
}

# Scan for orphaned XDG directories (tool uninstalled, dir remains)
# Populates _Z_XDG_ORPHANS: key=expanded_target, value=command|size_kb|hint
_xdg_scan_orphans() {
    typeset -gA _Z_XDG_ORPHANS=()
    local stray_key val_str target rest hint movable command expanded_target expanded_stray sz
    for stray_key val_str in ${(kv)Z_XDG_MIGRATIONS}; do
        target="${val_str%%|*}"
        rest="${val_str#*|}"
        hint="${rest%%|*}"
        rest="${rest#*|}"
        movable="${rest%%|*}"
        rest="${rest#*|}"
        command="${rest%%|*}"

        # Skip if command is empty (always-present tools like less)
        [[ -z "$command" ]] && continue
        # Skip if tool IS installed (not orphaned)
        (( $+commands[$command] )) && continue

        expanded_target="${(e)target}"
        expanded_stray="${(e)stray_key}"
        # Check if the XDG target dir exists (orphan evidence)
        [[ ! -e "$expanded_target" ]] && continue
        # Skip if the stray also exists (migration will handle this, not orphan cleanup)
        [[ -e "$expanded_stray" ]] && continue

        sz=$(_xdg_size_kb "$expanded_target")
        _Z_XDG_ORPHANS[$expanded_target]="${command}|${sz}|${hint}"
    done
}

# ----------------------------------------------------------
# CONFLICT DETECTION
# ----------------------------------------------------------

_xdg_check_conflict() {
    local source="$1" target="$2"
    [[ ! -e "$source" ]] && echo "ERROR" && return 2
    [[ ! -e "$target" ]] && echo "CLEAR|0|0|0|0|0|0|0" && return 0

    local src_mt tgt_mt src_sz tgt_sz src_items tgt_items
    src_mt=$(_get_mtime "$source")
    tgt_mt=$(_get_mtime "$target")
    src_sz=$(_xdg_size_kb "$source")
    tgt_sz=$(_xdg_size_kb "$target")
    src_items=$(_xdg_item_count "$source")
    tgt_items=$(_xdg_item_count "$target")

    # Type mismatch
    if { [[ -d "$source" ]] && [[ -f "$target" ]]; } || \
       { [[ -f "$source" ]] && [[ -d "$target" ]]; }; then
        echo "TYPE_MISMATCH|${src_mt}|${tgt_mt}|${src_sz}|${tgt_sz}|${src_items}|${tgt_items}|0"
        return 1
    fi

    local days_diff=$(( (tgt_mt - src_mt) / 86400 ))
    if (( src_mt > tgt_mt )); then
        echo "SOURCE_NEWER|${src_mt}|${tgt_mt}|${src_sz}|${tgt_sz}|${src_items}|${tgt_items}|${days_diff}"
        return 0
    elif (( tgt_mt > src_mt )); then
        echo "TARGET_NEWER|${src_mt}|${tgt_mt}|${src_sz}|${tgt_sz}|${src_items}|${tgt_items}|${days_diff}"
        return 1
    else
        echo "SAME_TIME|${src_mt}|${tgt_mt}|${src_sz}|${tgt_sz}|${src_items}|${tgt_items}|0"
        return 1
    fi
}

# ----------------------------------------------------------
# ATOMIC MIGRATION
# Three-phase: backup → move → verify/restore
# ----------------------------------------------------------

_xdg_migrate_one() {
    local source="$1" target="$2" force="${3:-}" post_action="${4:-}"
    local state_dir
    state_dir=$(_xdg_state_dir)
    local log_file="$state_dir/xdg-guardian.log"
    local backup_base="$state_dir/xdg-guardian-backups"
    local target_backup=""

    # Ensure state directory exists before any log writes
    _ensure_dir "$state_dir" || return 1

    [[ ! -e "$source" ]] && return 1
    _xdg_is_skipped "$source" && return 0

    # Conflict check (unless forced)
    if [[ -e "$target" ]] && [[ "$force" != "--force" ]]; then
        local conflict_data rc
        conflict_data=$(_xdg_check_conflict "$source" "$target")
        rc=$?
        if (( rc == 1 )); then
            return 2
        elif (( rc == 2 )); then
            return 1
        fi
    fi

    # Phase A: Backup source
    _ensure_dir "$backup_base"

    # If forced and target exists, backup then remove target first
    if [[ -e "$target" ]] && [[ "$force" == "--force" ]]; then
        target_backup="${backup_base}/$(basename "$target").target.$(date +%s)"
        if ! cp -a "$target" "$target_backup" 2>/dev/null; then
            _log ERROR "XDG target backup failed: $target"
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR target-backup $target (cp failed)" >> "$log_file"
            return 1
        fi
        rm -rf "$target"
    fi
    local backup_dir="${backup_base}/$(basename "$source").$(date +%s)"
    if ! cp -a "$source" "$backup_dir" 2>/dev/null; then
        _log ERROR "XDG backup failed: $source -> $backup_dir"
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR backup $source (cp failed)" >> "$log_file"
        return 1
    fi

    # Phase B: Move
    _ensure_dir "${target:h}" || return 1
    if ! mv "$source" "$target" 2>/dev/null; then
        _log ERROR "XDG migration failed: $source -> $target"
        # Restore from backup
        mv "$backup_dir" "$source" 2>/dev/null
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR migrate $source -> $target (mv failed, restored)" >> "$log_file"
        return 1
    fi

    # Phase C: Verify
    if [[ ! -e "$target" ]] || [[ -e "$source" && ! -L "$source" ]]; then
        _log ERROR "XDG migration verification failed: $source -> $target"
        # Attempt restore
        rm -rf "$target" 2>/dev/null
        mv "$backup_dir" "$source" 2>/dev/null
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR verify $source -> $target (restored)" >> "$log_file"
        return 1
    fi

    # Post-action: symlink_if_old (CUPS version-aware)
    if [[ "$post_action" == "symlink_if_old" ]]; then
        local tool_ver
        tool_ver=$(cups-config --version 2>/dev/null || echo "2.0")
        if [[ "${tool_ver%%.*}" -lt 3 ]]; then
            ln -s "$target" "$source" 2>/dev/null
        fi
    fi

    # Success: clean backups (source + target if forced), log
    rm -rf "$backup_dir"
    [[ -n "${target_backup:-}" ]] && rm -rf "$target_backup"
    echo "$(date '+%Y-%m-%d %H:%M:%S') MIGRATE $source -> $target" >> "$log_file"
    _log INFO "XDG migrated: $source -> $target"
    return 0
}

# Clean old backups (>7 days) and rotate log
_xdg_clean_old_backups() {
    local state_dir="$(_xdg_state_dir)"
    local backup_base="$state_dir/xdg-guardian-backups"

    # Prune backup dirs older than 7 days
    if [[ -d "$backup_base" ]]; then
        local now="$EPOCHSECONDS" dir_path dir_ts
        for dir_path in "$backup_base"/*(N/); do
            dir_ts="${dir_path##*.}"
            [[ "$dir_ts" =~ ^[0-9]+$ ]] || continue
            (( now - dir_ts > 604800 )) && rm -rf "$dir_path"
        done
    fi

    # Rotate log: keep last 100 lines
    local log_file="$state_dir/xdg-guardian.log"
    if [[ -f "$log_file" ]]; then
        local line_count
        line_count=$(wc -l < "$log_file" | tr -d ' ')
        if (( line_count > 100 )); then
            local tmp_log="${log_file}.tmp"
            tail -n 100 "$log_file" > "$tmp_log" && mv "$tmp_log" "$log_file"
        fi
    fi
}

# ----------------------------------------------------------
# CLASSIFICATION
# Sorts findings into buckets for display
# ----------------------------------------------------------

# Classify all findings into ready/conflicts/unmanaged arrays
# Sets: _Z_XDG_READY, _Z_XDG_CONFLICTS, _Z_XDG_UNMANAGED (indexed arrays)
# Each entry: stray_path|target|hint|command|post_action|size|date|items[|conflict_data]
_xdg_classify() {
    typeset -ga _Z_XDG_READY=() _Z_XDG_CONFLICTS=() _Z_XDG_UNMANAGED=()

    local stray_path data fields is_managed movable_str target_hint hint_text command post_action
    local sz mt items cdata crc display_name program_name unmov_reason
    for stray_path data in ${(kv)_Z_XDG_FINDINGS}; do
        fields=("${(@s:|:)data}")
        is_managed=false
        movable_str=""
        target_hint=""
        hint_text=""
        command=""
        post_action=""

        if [[ "${fields[-1]}" == "managed" ]]; then
            is_managed=true
            target_hint="${fields[1]}"
            hint_text="${fields[2]}"
            movable_str="${fields[3]}"
            command="${fields[4]}"
            post_action="${fields[5]}"
        else
            # ninja: help_line|movable|program|ninja
            hint_text="${fields[1]}"
            movable_str="${fields[2]}"
        fi

        sz=$(_xdg_size_kb "$stray_path")
        mt=$(_get_mtime "$stray_path")
        items=$(_xdg_item_count "$stray_path")

        # Unmanaged or unmovable → unmanaged bucket
        if ! $is_managed || [[ "$movable_str" != "true" ]]; then
            program_name="${fields[3]:-unknown}"
            unmov_reason=""
            [[ "$movable_str" != "true" ]] && unmov_reason="not movable"
            ! $is_managed && unmov_reason="xdg-ninja only"
            _Z_XDG_UNMANAGED+=("${stray_path}|${program_name}|${unmov_reason}|${sz}|${movable_str}")
            continue
        fi

        display_name=$(_xdg_tool_name "$stray_path")

        # Target exists → always a conflict (mv can't replace existing dirs)
        if [[ -e "$target_hint" ]]; then
            cdata=$(_xdg_check_conflict "$stray_path" "$target_hint")
            _Z_XDG_CONFLICTS+=("${stray_path}|${target_hint}|${hint_text}|${display_name}|${post_action}|${sz}|${mt}|${items}|${cdata}")
            continue
        fi

        # Clean migration candidate
        _Z_XDG_READY+=("${stray_path}|${target_hint}|${hint_text}|${display_name}|${post_action}|${sz}|${mt}|${items}")
    done
}

# ----------------------------------------------------------
# GUARDIAN HOOK (foreground, interactive)
# ----------------------------------------------------------

_xdg_guardian_hook() {
    [[ "$Z_XDG_GUARDIAN_ENABLED" != "true" ]] && return 0

    local state_dir
    state_dir=$(_xdg_state_dir)
    local timestamp_file="$state_dir/xdg-guardian.last"
    local findings_file="$state_dir/xdg-guardian.findings"

    # Check if scan is needed
    local now="$EPOCHSECONDS"
    local last_check=0
    if [[ -f "$timestamp_file" ]]; then
        last_check=$(<"$timestamp_file")
        [[ "$last_check" =~ ^[0-9]+$ ]] || last_check=0
    fi
    (( now - last_check < Z_XDG_GUARDIAN_INTERVAL )) && return 0

    # Show last check info
    if (( last_check > 0 )); then
        local last_date rel_time
        last_date=$(date -r "$last_check" '+%d %b %Y at %H:%M' 2>/dev/null || date -d "@$last_check" '+%d %b %Y at %H:%M' 2>/dev/null || echo "unknown")
        rel_time=$(_xdg_format_relative_time "$last_check")
        echo ""
        _ui_dim "XDG Guardian: last check ${last_date} (${rel_time}). Running new scan..."
    else
        echo ""
        _ui_dim "XDG Guardian: first scan. Running..."
    fi

    # Foreground scan
    typeset -gA _Z_XDG_FINDINGS=()
    _xdg_scan_ninja
    _xdg_scan_registry
    _xdg_scan_orphans
    _xdg_classify

    local ready_count=${#_Z_XDG_READY}
    local conflict_count=${#_Z_XDG_CONFLICTS}
    local orphan_count=${#_Z_XDG_ORPHANS}
    local total=$(( ready_count + conflict_count + orphan_count ))

    # Write findings file for z_xdg_status
    _ensure_dir "$state_dir"
    local sp d
    {
        echo "# XDG Guardian scan: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        for sp d in ${(kv)_Z_XDG_FINDINGS}; do
            echo "STRAY|${sp}|${d}"
        done
    } >| "$findings_file"

    # Auto-fix clean items if enabled
    local auto_migrated=0
    if [[ "$Z_XDG_GUARDIAN_AUTO_FIX" == "true" ]] && (( ready_count > 0 )); then
        local entry ef_stray ef_target ef_hint ef_cmd ef_post ef_rest
        for entry in "${_Z_XDG_READY[@]}"; do
            ef_stray="${entry%%|*}"
            ef_rest="${entry#*|}"
            ef_target="${ef_rest%%|*}"
            ef_rest="${ef_rest#*|}"
            ef_hint="${ef_rest%%|*}"
            ef_rest="${ef_rest#*|}"
            ef_cmd="${ef_rest%%|*}"
            ef_rest="${ef_rest#*|}"
            ef_post="${ef_rest%%|*}"

            _xdg_migrate_one "$ef_stray" "$ef_target" "" "$ef_post"
            if (( $? == 0 )); then
                (( auto_migrated++ ))
            fi
        done
        (( ready_count -= auto_migrated ))
    fi

    # Update timestamp
    echo "$EPOCHSECONDS" >| "$timestamp_file"

    # Clean old backups
    _xdg_clean_old_backups

    # Summary
    if (( total == 0 )); then
        _ui_ok "XDG Guardian: all clean"
        echo ""
        return 0
    fi

    # Build summary line
    local parts=()
    (( auto_migrated > 0 )) && parts+=("${auto_migrated} auto-migrated")
    (( ready_count > 0 )) && parts+=("${ready_count} ready to migrate")
    (( conflict_count > 0 )) && parts+=("${conflict_count} conflict(s)")
    (( orphan_count > 0 )) && parts+=("${orphan_count} orphan(s)")
    _ui_warn "XDG Guardian: ${(j:, :)parts}"

    # Ask if user wants details (only in interactive shell)
    if _is_interactive; then
        printf "  View details? [y/n]: "
        local choice
        read -k 1 choice; echo ""
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            # z_xdg_check will offer inline resolution via its own prompt
            z_xdg_check
        fi
    fi
    echo ""
    return 0
}

# ----------------------------------------------------------
# PUBLIC COMMANDS
# ----------------------------------------------------------

z_xdg_check() {
    local quick=false
    [[ "${1:-}" == "--quick" ]] && quick=true

    _ui_header "XDG Compliance Check"

    # Data sources
    _ui_section "Data Sources"
    local ninja_dir ninja_count
    ninja_dir=$(_xdg_ninja_db_path)
    if [[ $? -eq 0 ]] && ! $quick; then
        ninja_count=$(ls "$ninja_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')
        _ui_kv "xdg-ninja" "${ninja_count} programs" "ok"
    elif $quick; then
        _ui_kv "xdg-ninja" "skipped (--quick)" "dim"
    else
        _ui_kv "xdg-ninja" "not installed" "warn" "brew install xdg-ninja"
    fi
    _ui_kv "Registry" "${#Z_XDG_MIGRATIONS} managed tools" "ok"
    echo ""

    # Scan
    typeset -gA _Z_XDG_FINDINGS=()
    if ! $quick; then
        _xdg_scan_ninja
    fi
    _xdg_scan_registry
    _xdg_scan_orphans
    _xdg_classify

    local item_num=0

    # Ready to Migrate
    if (( ${#_Z_XDG_READY} > 0 )); then
        _ui_section "Ready to Migrate"
        local entry stray_path target_path hint_text cmd_name post_act sz_kb mt_epoch item_cnt r
        local short_src short_tgt fmt_sz fmt_dt
        for entry in "${_Z_XDG_READY[@]}"; do
            (( item_num++ ))
            stray_path="${entry%%|*}"
            r="${entry#*|}"
            target_path="${r%%|*}"; r="${r#*|}"
            hint_text="${r%%|*}"; r="${r#*|}"
            cmd_name="${r%%|*}"; r="${r#*|}"
            post_act="${r%%|*}"; r="${r#*|}"
            sz_kb="${r%%|*}"; r="${r#*|}"
            mt_epoch="${r%%|*}"; r="${r#*|}"
            item_cnt="${r%%|*}"

            short_src="~/${stray_path#$HOME/}"
            short_tgt="~/${target_path#$HOME/}"
            fmt_sz=$(_xdg_format_size "$sz_kb")
            fmt_dt=$(_xdg_format_date_short "$mt_epoch")

            printf "  ${_UI_GREEN}%2d.${_UI_RESET} ${_UI_BOLD}%-14s${_UI_RESET} %s ${_UI_DIM}→${_UI_RESET} %s" \
                "$item_num" "${cmd_name:-unknown}" "$short_src" "$short_tgt"
            printf "%*s${_UI_DIM}%7s  %s${_UI_RESET}\n" \
                $(( 50 - ${#short_src} - ${#short_tgt} )) "" "$fmt_sz" "$fmt_dt"
        done
        echo ""
    fi

    # Conflicts
    if (( ${#_Z_XDG_CONFLICTS} > 0 )); then
        _ui_section "Conflicts (target already exists)"
        local entry stray_path target_path hint_text cmd_name post_act sz_kb mt_epoch item_cnt cdata r
        local short_src short_tgt fmt_sz fmt_dt cfields conflict_type
        local tgt_sz tgt_mt tgt_items abs_days age_label
        for entry in "${_Z_XDG_CONFLICTS[@]}"; do
            (( item_num++ ))
            stray_path="${entry%%|*}"
            r="${entry#*|}"
            target_path="${r%%|*}"; r="${r#*|}"
            hint_text="${r%%|*}"; r="${r#*|}"
            cmd_name="${r%%|*}"; r="${r#*|}"
            post_act="${r%%|*}"; r="${r#*|}"
            sz_kb="${r%%|*}"; r="${r#*|}"
            mt_epoch="${r%%|*}"; r="${r#*|}"
            item_cnt="${r%%|*}"; r="${r#*|}"
            cdata="$r"

            cfields=("${(@s:|:)cdata}")
            conflict_type="${cfields[1]}"

            short_src="~/${stray_path#$HOME/}"
            short_tgt="~/${target_path#$HOME/}"
            fmt_sz=$(_xdg_format_size "$sz_kb")
            fmt_dt=$(_xdg_format_date_short "$mt_epoch")
            tgt_sz=$(_xdg_format_size "${cfields[5]}")
            tgt_mt=$(_xdg_format_date_short "${cfields[3]}")
            tgt_items="${cfields[7]}"

            # Age label
            abs_days=${cfields[8]#-}
            age_label=""
            if [[ "$conflict_type" == "TARGET_NEWER" ]]; then
                age_label="${_UI_YELLOW}← NEWER by ${abs_days} day(s)${_UI_RESET}"
            elif [[ "$conflict_type" == "SOURCE_NEWER" ]]; then
                age_label="${_UI_DIM}← OLDER by ${abs_days} day(s)${_UI_RESET}"
            elif [[ "$conflict_type" == "TYPE_MISMATCH" ]]; then
                age_label="${_UI_RED}← TYPE MISMATCH${_UI_RESET}"
            fi

            printf "  ${_UI_RED}%2d.${_UI_RESET} ${_UI_BOLD}%-14s${_UI_RESET} %s ${_UI_DIM}→${_UI_RESET} %s" \
                "$item_num" "${cmd_name:-unknown}" "$short_src" "$short_tgt"
            printf "%*s${_UI_DIM}%7s  %s${_UI_RESET}\n" \
                $(( 50 - ${#short_src} - ${#short_tgt} )) "" "$fmt_sz" "$fmt_dt"
            printf "                    Target: %-40s ${_UI_DIM}%7s  %s${_UI_RESET}  %s\n" \
                "$short_tgt" "$tgt_sz" "$tgt_mt" "$age_label"
        done
        echo ""
    fi

    # Orphaned XDG Directories
    if (( ${#_Z_XDG_ORPHANS} > 0 )); then
        _ui_section "Orphaned XDG Directories"
        local orphan_path orphan_data orphan_cmd orphan_sz orphan_hint short_orphan fmt_orphan_sz or
        for orphan_path orphan_data in ${(kv)_Z_XDG_ORPHANS}; do
            (( item_num++ ))
            orphan_cmd="${orphan_data%%|*}"
            or="${orphan_data#*|}"
            orphan_sz="${or%%|*}"
            orphan_hint="${or#*|}"

            short_orphan="~/${orphan_path#$HOME/}"
            fmt_orphan_sz=$(_xdg_format_size "$orphan_sz")

            printf "  ${_UI_YELLOW}%2d.${_UI_RESET} ${_UI_BOLD}%-14s${_UI_RESET} %s ${_UI_DIM}(%s not installed)${_UI_RESET}" \
                "$item_num" "$orphan_cmd" "$short_orphan" "$orphan_cmd"
            printf "%*s${_UI_DIM}%7s${_UI_RESET}\n" \
                $(( 40 - ${#short_orphan} )) "" "$fmt_orphan_sz"
        done
        echo ""
    fi

    # Not Managed (xdg-ninja only)
    local unmanaged_shown=0
    if (( ${#_Z_XDG_UNMANAGED} > 0 )); then
        _ui_section "Not Managed (xdg-ninja only)"
        local uentry u_path u_program u_reason u_sz u_movable short_u ur movable_tag
        for uentry in "${_Z_XDG_UNMANAGED[@]}"; do
            u_path="${uentry%%|*}"
            ur="${uentry#*|}"
            u_program="${ur%%|*}"; ur="${ur#*|}"
            u_reason="${ur%%|*}"; ur="${ur#*|}"
            u_sz="${ur%%|*}"; ur="${ur#*|}"
            u_movable="${ur%%|*}"

            short_u="~/${u_path#$HOME/}"
            movable_tag=""
            [[ "$u_movable" != "true" ]] && movable_tag=" — upstream unsupported"

            _ui_dim "  ${u_program}: ${short_u}${movable_tag}"
            (( unmanaged_shown++ ))
        done
        echo ""
    fi

    # Summary
    _ui_footer
    local total_items=$item_num
    local summary_parts=()
    (( ${#_Z_XDG_READY} > 0 )) && summary_parts+=("${#_Z_XDG_READY} ready")
    (( ${#_Z_XDG_CONFLICTS} > 0 )) && summary_parts+=("${#_Z_XDG_CONFLICTS} conflict(s)")
    (( ${#_Z_XDG_ORPHANS} > 0 )) && summary_parts+=("${#_Z_XDG_ORPHANS} orphan(s)")
    (( unmanaged_shown > 0 )) && summary_parts+=("${unmanaged_shown} unmanaged")

    if (( total_items > 0 )); then
        echo "  ${total_items} items: ${(j:, :)summary_parts}"
        # Offer inline resolution if interactive (unless suppressed by hook)
        if [[ "${_xdg_no_prompt:-}" != "true" ]] && _is_interactive; then
            echo ""
            printf "  Would you like to resolve now? [y/n]: "
            local resolve_choice
            read -k 1 resolve_choice; echo ""
            if [[ "$resolve_choice" == "y" || "$resolve_choice" == "Y" ]]; then
                echo ""
                z_xdg_fix
            fi
        else
            echo "  Run ${_UI_GREEN}xdg-fix${_UI_RESET} to resolve."
        fi
    else
        echo "  ${_UI_GREEN}All clean — no stray dotfiles found.${_UI_RESET}"
    fi
    echo ""

    return $(( total_items > 0 ? 1 : 0 ))
}

# ----------------------------------------------------------
# FZF CONFLICT RESOLVER
# ----------------------------------------------------------

_xdg_resolve_conflict_fzf() {
    local stray_path="$1" target_path="$2" hint_text="$3"
    local cmd_name="$4" post_action="$5" cdata="$6"

    local short_src="~/${stray_path#$HOME/}"
    local short_tgt="~/${target_path#$HOME/}"
    local cfields=("${(@s:|:)cdata}")
    local conflict_type="${cfields[1]}"
    local src_mt=$(_xdg_format_date "${cfields[2]}")
    local tgt_mt=$(_xdg_format_date "${cfields[3]}")
    local src_sz=$(_xdg_format_size "${cfields[4]}")
    local tgt_sz=$(_xdg_format_size "${cfields[5]}")
    local src_items="${cfields[6]}"
    local tgt_items="${cfields[7]}"
    local abs_days="${cfields[8]#-}"

    local age_note=""
    if [[ "$conflict_type" == "TARGET_NEWER" ]]; then
        age_note="Target is NEWER by ${abs_days} day(s)"
    elif [[ "$conflict_type" == "SOURCE_NEWER" ]]; then
        age_note="Source is NEWER by ${abs_days} day(s)"
    elif [[ "$conflict_type" == "TYPE_MISMATCH" ]]; then
        age_note="TYPE MISMATCH (file vs directory)"
    fi

    local preview_text
    preview_text=$(printf '%s\n\n  SOURCE: %s\n    Modified: %s\n    Size:     %s\n    Items:    %s\n\n  TARGET: %s\n    Modified: %s\n    Size:     %s\n    Items:    %s\n\n  %s\n\n  Hint: %s' \
        "" "$short_src" "$src_mt" "$src_sz" "$src_items" \
        "$short_tgt" "$tgt_mt" "$tgt_sz" "$tgt_items" \
        "$age_note" "$hint_text")

    local selection
    selection=$(printf '%s\n' \
        "Use source ($short_src) — move to XDG location" \
        "Use target ($short_tgt) — delete stale source" \
        "Skip — keep both, no action" \
        "Skip permanently — never ask again" \
    | fzf \
        --ansi \
        --height=60% \
        --layout=reverse \
        --border=rounded \
        --prompt="Choose action: " \
        --header="${cmd_name}: ${short_src} vs ${short_tgt}" \
        --preview="echo '$preview_text'" \
        --preview-window="right:55%:wrap" \
        --pointer=">" \
        --color="fg:#abb2bf,bg:-1,hl:#98c379,fg+:#abb2bf,bg+:#2c323c,hl+:#98c379,info:#e5c07b,prompt:#c678dd,pointer:#61afef,marker:#e5c07b,spinner:#e5c07b,header:#e06c75" \
        --no-multi \
    )

    case "$selection" in
        "Use source"*)      echo "source" ;;
        "Use target"*)      echo "target" ;;
        "Skip permanently"*) echo "skip_permanent" ;;
        *)                  echo "skip" ;;
    esac
}

# Fallback for no fzf
_xdg_resolve_conflict_menu() {
    local stray_path="$1" target_path="$2" hint_text="$3" cdata="$4"

    local short_src="~/${stray_path#$HOME/}"
    local short_tgt="~/${target_path#$HOME/}"
    local cfields=("${(@s:|:)cdata}")
    local conflict_type="${cfields[1]}"
    local abs_days="${cfields[8]#-}"

    echo ""
    echo "    ${_UI_DIM}Source:${_UI_RESET} $short_src ($(_xdg_format_date "${cfields[2]}"), $(_xdg_format_size "${cfields[4]}"), ${cfields[6]} items)"
    echo "    ${_UI_DIM}Target:${_UI_RESET} $short_tgt ($(_xdg_format_date "${cfields[3]}"), $(_xdg_format_size "${cfields[5]}"), ${cfields[7]} items)"
    if [[ "$conflict_type" == "TARGET_NEWER" ]]; then
        echo "    ${_UI_YELLOW}Target is NEWER by ~${abs_days} day(s)${_UI_RESET}"
    elif [[ "$conflict_type" == "TYPE_MISMATCH" ]]; then
        echo "    ${_UI_RED}TYPE MISMATCH (file vs directory)${_UI_RESET}"
    fi
    echo ""
    echo "    1) Use source (move to XDG, overwrite target)"
    echo "    2) Use target (delete stale source)"
    echo "    3) Skip"
    echo "    4) Skip permanently (never ask again)"
    printf "    Choice [1-4]: "
    local choice
    read -k 1 choice; echo ""
    case "$choice" in
        1) echo "source" ;;
        2) echo "target" ;;
        4) echo "skip_permanent" ;;
        *) echo "skip" ;;
    esac
}

# ----------------------------------------------------------
# XDG FIX — Two-phase migration
# ----------------------------------------------------------

z_xdg_fix() {
    local mode="interactive" dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto) mode="auto"; shift ;;
            --dry-run) dry_run=true; shift ;;
            *) echo "Usage: xdg-fix [--auto|--dry-run]"; return 1 ;;
        esac
    done

    _ui_header "XDG Migration"

    # Scan
    typeset -gA _Z_XDG_FINDINGS=()
    _xdg_scan_ninja
    _xdg_scan_registry
    _xdg_scan_orphans
    _xdg_classify

    local migrated=0 skipped=0 conflict_resolved=0 errors=0 orphans_removed=0

    # Phase 1: Clean migrations (batch)
    if (( ${#_Z_XDG_READY} > 0 )); then
        _ui_section "Ready to Migrate"
        local item_num=0
        local entry stray_path target_path hint_text cmd_name post_act sz_kb mt_epoch item_cnt r
        local short_src short_tgt
        for entry in "${_Z_XDG_READY[@]}"; do
            (( item_num++ ))
            stray_path="${entry%%|*}"
            r="${entry#*|}"
            target_path="${r%%|*}"; r="${r#*|}"
            hint_text="${r%%|*}"; r="${r#*|}"
            cmd_name="${r%%|*}"; r="${r#*|}"
            post_act="${r%%|*}"; r="${r#*|}"
            sz_kb="${r%%|*}"; r="${r#*|}"
            mt_epoch="${r%%|*}"; r="${r#*|}"
            item_cnt="${r%%|*}"

            short_src="~/${stray_path#$HOME/}"
            short_tgt="~/${target_path#$HOME/}"

            printf "  ${_UI_GREEN}%2d.${_UI_RESET} ${_UI_BOLD}%-14s${_UI_RESET} %s ${_UI_DIM}→${_UI_RESET} %s\n" \
                "$item_num" "${cmd_name:-unknown}" "$short_src" "$short_tgt"
            printf "                    ${_UI_DIM}%s | Modified %s | %s${_UI_RESET}\n" \
                "$(_xdg_format_size "$sz_kb")" "$(_xdg_format_date_short "$mt_epoch")" "$hint_text"
        done
        echo ""

        if $dry_run; then
            _ui_ok "[DRY RUN] Would migrate ${#_Z_XDG_READY} item(s)"
            (( migrated += ${#_Z_XDG_READY} ))
        elif [[ "$mode" == "auto" ]]; then
            # Auto-migrate all
            for entry in "${_Z_XDG_READY[@]}"; do
                stray_path="${entry%%|*}"
                r="${entry#*|}"
                target_path="${r%%|*}"; r="${r#*|}"
                hint_text="${r%%|*}"; r="${r#*|}"
                cmd_name="${r%%|*}"; r="${r#*|}"
                post_act="${r%%|*}"

                _xdg_migrate_one "$stray_path" "$target_path" "" "$post_act"
                case $? in
                    0) _ui_ok "Migrated ${cmd_name}: $short_src"; (( migrated++ )) ;;
                    *) _ui_error "Failed: ${cmd_name}"; (( errors++ )) ;;
                esac
            done
        else
            # Interactive batch prompt
            printf "  Migrate all ${#_Z_XDG_READY} item(s)? [y]es / [n]o / [p]ick individually: "
            local batch_choice
            read -k 1 batch_choice; echo ""
            case "$batch_choice" in
                y|Y)
                    for entry in "${_Z_XDG_READY[@]}"; do
                        stray_path="${entry%%|*}"
                        r="${entry#*|}"
                        target_path="${r%%|*}"; r="${r#*|}"
                        hint_text="${r%%|*}"; r="${r#*|}"
                        cmd_name="${r%%|*}"; r="${r#*|}"
                        post_act="${r%%|*}"

                        short_src="~/${stray_path#$HOME/}"
                        _xdg_migrate_one "$stray_path" "$target_path" "" "$post_act"
                        case $? in
                            0) _ui_ok "Migrated ${cmd_name}: ${short_src}"; (( migrated++ )) ;;
                            *) _ui_error "Failed: ${cmd_name}"; (( errors++ )) ;;
                        esac
                    done
                    ;;
                p|P)
                    for entry in "${_Z_XDG_READY[@]}"; do
                        stray_path="${entry%%|*}"
                        r="${entry#*|}"
                        target_path="${r%%|*}"; r="${r#*|}"
                        hint_text="${r%%|*}"; r="${r#*|}"
                        cmd_name="${r%%|*}"; r="${r#*|}"
                        post_act="${r%%|*}"

                        short_src="~/${stray_path#$HOME/}"
                        printf "  Migrate ${_UI_BOLD}${cmd_name}${_UI_RESET}? [y]es / [n]o / [s]kip permanently: "
                        local pick
                        read -k 1 pick; echo ""
                        case "$pick" in
                            y|Y)
                                _xdg_migrate_one "$stray_path" "$target_path" "" "$post_act"
                                case $? in
                                    0) _ui_ok "Migrated ${cmd_name}"; (( migrated++ )) ;;
                                    *) _ui_error "Failed: ${cmd_name}"; (( errors++ )) ;;
                                esac
                                ;;
                            s|S)
                                _xdg_skip_permanently "$stray_path"
                                _ui_dim "  Permanently skipped ${cmd_name}"
                                (( skipped++ ))
                                ;;
                            *)
                                (( skipped++ ))
                                ;;
                        esac
                    done
                    ;;
                *)
                    (( skipped += ${#_Z_XDG_READY} ))
                    ;;
            esac
        fi
        echo ""
    fi

    # Phase 2: Conflicts (fzf or fallback)
    if (( ${#_Z_XDG_CONFLICTS} > 0 )); then
        _ui_section "Conflicts"
        local entry stray_path target_path hint_text cmd_name post_act sz_kb mt_epoch item_cnt cdata r
        local short_src short_tgt resolution
        for entry in "${_Z_XDG_CONFLICTS[@]}"; do
            stray_path="${entry%%|*}"
            r="${entry#*|}"
            target_path="${r%%|*}"; r="${r#*|}"
            hint_text="${r%%|*}"; r="${r#*|}"
            cmd_name="${r%%|*}"; r="${r#*|}"
            post_act="${r%%|*}"; r="${r#*|}"
            sz_kb="${r%%|*}"; r="${r#*|}"
            mt_epoch="${r%%|*}"; r="${r#*|}"
            item_cnt="${r%%|*}"; r="${r#*|}"
            cdata="$r"

            short_src="~/${stray_path#$HOME/}"
            short_tgt="~/${target_path#$HOME/}"

            if $dry_run; then
                _ui_warn "[DRY RUN] Conflict: ${cmd_name} (${short_src} vs ${short_tgt})"
                (( conflict_resolved++ ))
                continue
            fi

            if [[ "$mode" == "auto" ]]; then
                _ui_warn "[AUTO] Skipping conflict: ${cmd_name}"
                (( skipped++ ))
                continue
            fi

            echo ""
            printf "  ${_UI_RED}●${_UI_RESET} ${_UI_BOLD}%-14s${_UI_RESET} %s ${_UI_DIM}vs${_UI_RESET} %s\n" \
                "${cmd_name:-unknown}" "$short_src" "$short_tgt"

            # Resolve via fzf or fallback
            resolution=""
            if _has_cmd fzf; then
                resolution=$(_xdg_resolve_conflict_fzf "$stray_path" "$target_path" "$hint_text" "$cmd_name" "$post_act" "$cdata")
            else
                resolution=$(_xdg_resolve_conflict_menu "$stray_path" "$target_path" "$hint_text" "$cdata")
            fi

            case "$resolution" in
                source)
                    _xdg_migrate_one "$stray_path" "$target_path" "--force" "$post_act"
                    if (( $? == 0 )); then
                        _ui_ok "Migrated ${cmd_name}: source → target"
                        (( conflict_resolved++ ))
                    else
                        _ui_error "Failed: ${cmd_name}"
                        (( errors++ ))
                    fi
                    ;;
                target)
                    rm -rf "$stray_path"
                    _ui_ok "Kept target, removed source: ${short_src}"
                    (( conflict_resolved++ ))
                    ;;
                skip_permanent)
                    _xdg_skip_permanently "$stray_path"
                    _ui_dim "  Permanently skipped ${cmd_name}"
                    (( skipped++ ))
                    ;;
                *)
                    _ui_dim "  Skipped ${cmd_name}"
                    (( skipped++ ))
                    ;;
            esac
        done
        echo ""
    fi

    # Phase 3: Orphans
    if (( ${#_Z_XDG_ORPHANS} > 0 )) && ! $dry_run; then
        _ui_section "Orphaned XDG Directories"
        local orphan_path orphan_data orphan_cmd orphan_sz orphan_hint short_orphan or
        for orphan_path orphan_data in ${(kv)_Z_XDG_ORPHANS}; do
            orphan_cmd="${orphan_data%%|*}"
            or="${orphan_data#*|}"
            orphan_sz="${or%%|*}"
            orphan_hint="${or#*|}"

            short_orphan="~/${orphan_path#$HOME/}"
            printf "  ${_UI_YELLOW}●${_UI_RESET} ${_UI_BOLD}%-14s${_UI_RESET} %s ${_UI_DIM}(%s not installed, %s)${_UI_RESET}\n" \
                "$orphan_cmd" "$short_orphan" "$orphan_cmd" "$(_xdg_format_size "$orphan_sz")"

            if [[ "$mode" == "auto" ]]; then
                rm -rf "$orphan_path"
                _ui_ok "Removed orphan: $short_orphan"
                (( orphans_removed++ ))
            else
                printf "     [y]es / [n]o / [s]kip permanently: "
                local oc
                read -k 1 oc; echo ""
                case "$oc" in
                    y|Y)
                        rm -rf "$orphan_path"
                        _ui_ok "Removed: $short_orphan"
                        (( orphans_removed++ ))
                        ;;
                    s|S)
                        _xdg_skip_permanently "$orphan_path"
                        _ui_dim "  Permanently skipped $orphan_cmd"
                        (( skipped++ ))
                        ;;
                    *)
                        (( skipped++ ))
                        ;;
                esac
            fi
        done
        echo ""
    elif (( ${#_Z_XDG_ORPHANS} > 0 )) && $dry_run; then
        _ui_section "Orphaned XDG Directories"
        local orphan_path orphan_data orphan_cmd orphan_sz short_orphan or
        for orphan_path orphan_data in ${(kv)_Z_XDG_ORPHANS}; do
            orphan_cmd="${orphan_data%%|*}"
            or="${orphan_data#*|}"
            orphan_sz="${or%%|*}"
            short_orphan="~/${orphan_path#$HOME/}"
            _ui_warn "[DRY RUN] Orphan: ${orphan_cmd} (${short_orphan}, $(_xdg_format_size "$orphan_sz"))"
            (( orphans_removed++ ))
        done
        echo ""
    fi

    # No items at all
    if (( ${#_Z_XDG_READY} == 0 && ${#_Z_XDG_CONFLICTS} == 0 && ${#_Z_XDG_ORPHANS} == 0 )); then
        _ui_ok "No stray dotfiles found. Everything is XDG-compliant!"
        return 0
    fi

    # Summary
    _ui_footer
    local summary_parts=()
    (( migrated > 0 )) && summary_parts+=("Migrated: $migrated")
    (( conflict_resolved > 0 )) && summary_parts+=("Resolved: $conflict_resolved")
    (( orphans_removed > 0 )) && summary_parts+=("Orphans removed: $orphans_removed")
    (( skipped > 0 )) && summary_parts+=("Skipped: $skipped")
    (( errors > 0 )) && summary_parts+=("Errors: $errors")
    echo "  ${(j: | :)summary_parts}"
    echo ""
}

z_xdg_status() {
    local state_dir
    state_dir=$(_xdg_state_dir)
    local findings_file="$state_dir/xdg-guardian.findings"

    if [[ -s "$findings_file" ]]; then
        local count
        count=$(grep -c '^STRAY|' "$findings_file" 2>/dev/null)
        if (( count > 0 )); then
            echo "XDG: ${count} stray"
            return 1
        else
            echo "XDG: clean"
            return 0
        fi
    else
        echo "XDG: unknown (run xdg-check)"
        return 1
    fi
}

# ----------------------------------------------------------
# HOOK REGISTRATION
# ----------------------------------------------------------

Z_POST_INTERACTIVE_HOOKS+=('_xdg_guardian_hook')

_log DEBUG "XDG Guardian loaded"
