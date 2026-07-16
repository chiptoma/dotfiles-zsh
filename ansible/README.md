# Ansible Role: zsh_dotfiles

Installs the zsh dotfiles framework unattended on any supported distro
(and macOS), driving `install.sh` with its non-interactive flags and
verifying the result with `install.sh --check`.

## Quick start

```bash
ansible-playbook -i inventory ansible/playbook.yml
```

## Variables (defaults in `roles/zsh_dotfiles/defaults/main.yml`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `zsh_dotfiles_repo` | upstream URL | Repo to install (set your fork) |
| `zsh_dotfiles_version` | `main` | Branch or tag |
| `zsh_dotfiles_clone_dest` | `~/.local/src/dotfiles-zsh` | Clone location |
| `zsh_dotfiles_install_method` | `copy` | `copy` or `symlink` |
| `zsh_dotfiles_profile` | `recommended` | `minimal` / `recommended` / `full` |
| `zsh_dotfiles_tools` | `[]` | Explicit tool list (overrides profile) |
| `zsh_dotfiles_skip_tools` | `false` | Skip optional tools entirely |
| `zsh_dotfiles_set_default_shell` | `false` | Run `chsh` (needs privileges) |

## Idempotence

- The installer task uses `creates:` on `~/.config/zsh/.zshrc`, so re-runs
  skip installation; the `--check` verification always runs (`changed_when:
  false`) and fails the play if the installation is broken.
- The installer's own exit codes: `0` ok, `1` install error (rolled back),
  `2` usage error, `3` preflight failure — surfaced directly by the play.

## Notes

- `--no-default-shell` is passed unless `zsh_dotfiles_set_default_shell`
  is true: `chsh` can prompt for a password and hang unattended runs.
- The role never touches an existing `.zshlocal`; upgrades preserve it.
- Tool configs land per `tools/manifest.dat`, with pre-existing files
  backed up to `~/.zsh-backup-<timestamp>/` (restore: `install.sh --restore`).
