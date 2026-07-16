#!/usr/bin/env zsh
# ==============================================================================
# DOTFILES BACKUP & RESTORE
# Snapshot and restore of everything this framework manages: the shell entry
# files, ZDOTDIR, and shipped tool configs (tools/manifest.dat).
# ------------------------------------------------------------------------------
# NOTE: Backups share the installer's format (~/.zsh-backup-<ts> + MANIFEST),
#   so `install.sh --restore` and z_dotfiles_restore are interchangeable.
# ==============================================================================

# Idempotent guard
(( ${+_Z_FUNCTIONS_BACKUP_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_BACKUP_LOADED=1

# Expands a manifest dest template ($XDG_CONFIG_HOME, ~) to an absolute path
_z_backup_expand_dest() {
    local dest="$1"
    dest="${dest//\$XDG_CONFIG_HOME/${XDG_CONFIG_HOME:-$HOME/.config}}"
    dest="${dest/#\~/$HOME}"
    print -r -- "$dest"
}

# Create a timestamped backup of all framework-managed files.
# Usage: z_dotfiles_backup
z_dotfiles_backup() {
    local backup_dir="$HOME/.zsh-backup-$(date +%Y%m%d_%H%M%S)"
    local manifest="${ZSH_CONFIG_HOME:-${ZDOTDIR:-$HOME/.config/zsh}}/tools/manifest.dat"
    local -a targets=()
    local f

    for f in "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile"; do
        [[ -f "$f" ]] && targets+=("$f")
    done
    [[ -d "${ZDOTDIR:-$HOME/.config/zsh}" ]] && targets+=("${ZDOTDIR:-$HOME/.config/zsh}")

    mkdir -p "$backup_dir"
    : > "$backup_dir/MANIFEST"

    local base
    for f in "${targets[@]}"; do
        base="${f:t}"
        cp -r "$f" "$backup_dir/$base"
        printf '%s\t%s\n' "$f" "$base" >> "$backup_dir/MANIFEST"
        _ui_ok "Backed up $f"
    done

    if [[ -f "$manifest" ]]; then
        local line tool src dest mode dest_path
        while IFS= read -r line; do
            [[ -z "$line" || "$line" == \#* ]] && continue
            IFS=: read -r tool src dest mode <<< "$line"
            dest_path="$(_z_backup_expand_dest "$dest")"
            [[ -f "$dest_path" ]] || continue
            mkdir -p "$backup_dir/tools/$tool"
            cp "$dest_path" "$backup_dir/tools/$tool/${dest_path:t}"
            printf '%s\t%s\n' "$dest_path" "tools/$tool/${dest_path:t}" >> "$backup_dir/MANIFEST"
            _ui_ok "Backed up $dest_path"
        done < "$manifest"
    fi

    _ui_ok "Backup complete: $backup_dir"
}

# Restore a backup created by z_dotfiles_backup or install.sh.
# Usage: z_dotfiles_restore [backup-dir]   (newest ~/.zsh-backup-* by default)
z_dotfiles_restore() {
    local backup_dir="${1:-}"
    if [[ -z "$backup_dir" ]]; then
        backup_dir=$(ls -dt "$HOME"/.zsh-backup-* 2>/dev/null | head -1)
    fi
    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        _ui_error "No backup found (looked for ~/.zsh-backup-*)"
        return 1
    fi
    if [[ ! -f "$backup_dir/MANIFEST" ]]; then
        _ui_error "Backup has no MANIFEST (pre-2.0 backup?): $backup_dir"
        _ui_dim "Restore manually or via: install.sh --restore $backup_dir"
        return 1
    fi

    _ui_warn "This overwrites current dotfiles with: $backup_dir"
    local reply
    read -r "reply?  Continue? [y/N] "
    [[ "$reply" == [yY]* ]] || { _ui_dim "Restore cancelled"; return 1 }

    local orig rel
    while IFS=$'\t' read -r orig rel; do
        [[ -n "$orig" && -e "$backup_dir/$rel" ]] || continue
        mkdir -p "${orig:h}"
        if [[ -d "$backup_dir/$rel" ]]; then
            rm -rf "$orig"
            cp -r "$backup_dir/$rel" "$orig"
        else
            cp "$backup_dir/$rel" "$orig"
        fi
        _ui_ok "Restored $orig"
    done < "$backup_dir/MANIFEST"

    _ui_ok "Restore complete — start a new shell to pick it up"
}

_log DEBUG "ZSH Backup Functions Library loaded"
