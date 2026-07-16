# Tool Configurations

Curated, opinionated configs for the optional CLI tools, installed by
`install.sh` for every tool that is actually present on the machine.

## Layout

```
tools/
├── manifest.dat       # tool:source:dest:mode — drives installation
├── starship/          # prompt
├── atuin/             # history sync
├── bat/               # file viewer
├── ripgrep/           # search defaults (via RIPGREP_CONFIG_PATH)
├── delta/             # git diffs (wired via git include.path)
├── lazygit/           # git TUI
├── btm/               # system monitor
├── fastfetch/         # system info
└── tldr/              # tealdeer cache settings
```

## Behavior

- A config is only installed when its tool's binary is on `PATH`.
- Existing destination files are backed up to `<dest>.backup` first, and the
  pre-install versions are also captured in `~/.zsh-backup-<ts>/tools/` by
  the installer's unified backup (restore with `install.sh --restore` or
  the `dotrestore` shell command).
- `delta` uses mode `gitinclude`: the file is copied, then added once to
  git's global `include.path` — your `.gitconfig` itself is never rewritten.
- Tools that need only environment defaults (fzf, eza, zoxide, ...) are
  configured via `lib/registry/` env entries instead of shipped files.

## Customization

Edit the installed config at its destination (e.g. `~/.config/starship.toml`)
— the framework never overwrites it again unless you re-run the installer,
which backs it up first. To reject a shipped config entirely, restore the
`.backup` file it created.

## Adding a config

1. Create `tools/<tool>/<file>`.
2. Add a `tool:source:dest:mode` line to `manifest.dat`
   (`$XDG_CONFIG_HOME` and `~` are expanded in dest).
3. The structure test validates the manifest; `just test` covers it.
