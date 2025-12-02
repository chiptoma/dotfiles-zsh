# Aliases Module

Centralized alias definitions with modern tool replacements, organized by category.

## Features

- **Modern Tool Replacements** - Automatically uses `eza`, `bat`, `fd`, `ripgrep` when available
- **Safety Prompts** - Confirmation before destructive operations (`rm`, `mv`, `cp`)
- **Platform-Aware** - macOS and Linux-specific aliases load automatically
- **Interactive Browser** - Use `als` to search and discover all aliases

## Quick Reference

Type `als` (or `aliases`) to open an interactive fzf browser of all available aliases.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_ALIASES_ENABLED` | `true` | Enable/disable aliases module |
| `ZSH_ALIASES_MODERN_TOOLS` | `true` | Use modern CLI replacements |
| `ZSH_ALIASES_SAFETY_PROMPTS` | `true` | Confirm destructive operations |

---

## Safety Aliases

Enabled when `ZSH_ALIASES_SAFETY_PROMPTS=true`:

| Alias | Command | Description |
|-------|---------|-------------|
| `cp` | `cp -i` | Copy with confirmation |
| `mv` | `mv -i` | Move with confirmation |
| `rm` | `rm -i` | Remove with confirmation |
| `chmod` | `chmod -v` | Change permissions (verbose) |
| `chown` | `chown -v` | Change ownership (verbose) |
| `rmt` | `trash` | Move to trash (if installed) |

---

## Navigation

| Alias | Command | Description |
|-------|---------|-------------|
| `..` | `cd ..` | Go up 1 directory |
| `...` | `cd ../..` | Go up 2 directories |
| `....` | `cd ../../..` | Go up 3 directories |
| `.....` | `cd ../../../..` | Go up 4 directories |
| `-` | `cd -` | Previous directory |
| `home` | `cd ~` | Home directory |
| `dld` | `cd ~/Downloads` | Downloads |
| `dsk` | `cd ~/Desktop` | Desktop |
| `doc` | `cd ~/Documents` | Documents |
| `mkcd` | `zsh_mkcd` | Create dir and cd into it |
| `take` | `zsh_mkcd` | Create dir and cd into it |
| `up` | `zsh_up` | Navigate up N directories |
| `d` | `dirs -v \| head -10` | Show directory stack |
| `p` | `pushd` | Push to directory stack |

### Zoxide (if installed)

| Alias | Description |
|-------|-------------|
| `zz` | Go to previous directory |
| `zb` | Go back |

---

## File Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `md` | `mkdir -p` | Create nested directories |
| `rd` | `rmdir` | Remove empty directory |
| `c` / `cl` / `clr` / `cls` | `clear` | Clear terminal |
| `j` | `jobs -l` | List background jobs |
| `sizeof` | `zsh_sizeof` | Show size of file/dir |
| `backup` | `zsh_backup` | Create timestamped backup |
| `todos` | `zsh_todos` | Find TODO/FIXME comments |
| `extract` | `zsh_extract` | Universal archive extractor |
| `gitsize` | `zsh_gitsize` | Git-tracked file sizes |

### Yazi File Manager (if installed)

| Alias | Description |
|-------|-------------|
| `y` | Yazi with cd-on-exit |

---

## Modern Tool Replacements

These activate when `ZSH_ALIASES_MODERN_TOOLS=true` and the tool is installed:

### eza (ls replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `lt` | `eza --tree --level=2 --icons` | Tree view (2 levels) |
| `lta` | `eza --tree --level=2 -la --icons` | Tree all (2 levels) |
| `ltd` | `eza --tree --level=3 --icons` | Tree view (3 levels) |
| `ltda` | `eza --tree --level=3 -la --icons` | Tree all (3 levels) |

### bat (cat replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `cat` | `bat` | Syntax highlighting |
| `catp` | `bat --style=plain` | Plain output |
| `catn` | `bat --style=numbers` | With line numbers |

### fd (find replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `find` | `fd` | Modern find |
| `f` | `fd` | Quick search |
| `fde` | `fd --extension` | Find by extension |

### dust (du replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `du` | `dust` | Visual disk usage |
| `duhere` | `dust --depth 2` | Local disk usage |

### duf (df replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `df` | `duf` | Pretty disk free |
| `dfall` | `duf --all` | All filesystems |

### btm (top replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `top` | `btm` | Modern system monitor |
| `htop` | `btm` | Modern system monitor |

### procs (ps replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `pst` | `procs --tree` | Process tree |
| `pscpu` | `procs --sortd cpu` | Sort by CPU |
| `psmem` | `procs --sortd mem` | Sort by memory |

### ripgrep (grep replacement)

| Alias | Command | Description |
|-------|---------|-------------|
| `rgi` | `rg -i` | Case-insensitive |
| `rgf` | `rg -F` | Fixed string |
| `rgl` | `rg -l` | List files only |
| `rgc` | `rg -c` | Count matches |

### Other Modern Tools

| Alias | Tool | Description |
|-------|------|-------------|
| `ping` | `gping --clear` | Visual ping graph |
| `traceroute` | `trip -u` | Visual traceroute |
| `http` | `xh --pretty all` | HTTP client |
| `diffs` | `delta --side-by-side` | Side-by-side diff |
| `bandwidth` | `bandwhich` | Network monitor |
| `manual` / `help` | `tldr` | Quick command help |
| `bench` | `hyperfine` | Benchmarking |

---

## Git Aliases

Pattern: `g` + first letter of each word. Modifiers: `a`=all, `s`=staged, `f`=force, `m`=message.

### Status & Info

| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status --short --branch` | Short status |
| `gss` | `git status` | Full status |
| `gl` | `git log --oneline -20` | Last 20 commits |
| `gla` | `git log --oneline --all -20` | All branches |
| `glg` | `git log --graph --oneline -20` | Graph view |
| `glga` | `git log --graph --all` | Full graph |
| `gd` | `git diff` | Diff unstaged |
| `gds` | `git diff --staged` | Diff staged |
| `gsh` | `git show` | Show commit |

### Staging & Commits

| Alias | Command | Description |
|-------|---------|-------------|
| `ga` | `git add` | Add files |
| `gaa` | `git add --all` | Add all |
| `gap` | `git add --patch` | Interactive add |
| `gc` | `git commit` | Commit |
| `gcm` | `git commit -m` | Commit with message |
| `gca` | `git commit --amend` | Amend commit |
| `gcam` | `git commit --amend -m` | Amend with message |
| `gcan` | `git commit --amend --no-edit` | Amend no edit |

### Branches

| Alias | Command | Description |
|-------|---------|-------------|
| `gb` | `git branch` | List branches |
| `gba` | `git branch --all` | All branches |
| `gbd` | `git branch -d` | Delete (safe) |
| `gbD` | `git branch -D` | Delete (force) |
| `gco` | `git checkout` | Checkout |
| `gcb` | `git checkout -b` | New branch |
| `gsw` | `git switch` | Switch branch |
| `gswc` | `git switch -c` | New branch |

### Remote

| Alias | Command | Description |
|-------|---------|-------------|
| `gf` | `git fetch` | Fetch |
| `gfa` | `git fetch --all --prune` | Fetch all + prune |
| `gpl` | `git pull` | Pull |
| `gplr` | `git pull --rebase` | Pull rebase |
| `gps` | `git push` | Push |
| `gpsf` | `git push --force-with-lease` | Force push (safe) |
| `gpsu` | `git push -u origin HEAD` | Push + set upstream |

### Merge & Rebase

| Alias | Command | Description |
|-------|---------|-------------|
| `gm` | `git merge` | Merge |
| `gmom` | `git merge origin/main` | Merge origin/main |
| `grb` | `git rebase` | Rebase |
| `grbi` | `git rebase -i` | Interactive rebase |
| `grbm` | `git rebase main` | Rebase onto main |
| `grbc` | `git rebase --continue` | Continue |
| `grba` | `git rebase --abort` | Abort |

### Stash

| Alias | Command | Description |
|-------|---------|-------------|
| `gst` | `git stash` | Stash changes |
| `gstl` | `git stash list` | List stashes |
| `gstp` | `git stash pop` | Pop stash |
| `gsta` | `git stash apply` | Apply stash |
| `gstd` | `git stash drop` | Drop stash |
| `gstm` | `git stash push -m` | Stash with message |

### Undo & Reset

| Alias | Command | Description |
|-------|---------|-------------|
| `grs` | `git restore` | Restore file |
| `grss` | `git restore --staged` | Unstage file |
| `grh` | `git reset HEAD` | Soft reset |
| `grhh` | `git reset --hard HEAD` | Hard reset |
| `gundo` | `git reset HEAD~1` | Undo last commit |
| `gclean` | `git clean -fd` | Clean untracked |

### Other Git

| Alias | Command | Description |
|-------|---------|-------------|
| `gbl` | `git blame -w` | Blame (ignore whitespace) |
| `gcl` | `git clone --recurse-submodules` | Clone with submodules |
| `gcp` | `git cherry-pick` | Cherry-pick |
| `gt` | `git tag` | Tag |
| `gwt` | `git worktree` | Worktree |
| `gbi` | `git bisect` | Bisect |
| `lg` | `lazygit` | Lazygit TUI |
| `gcleanup` | `zsh_git_cleanup` | Delete merged branches |

---

## Docker

| Alias | Command | Description |
|-------|---------|-------------|
| `dc` | `docker-compose` | Docker Compose |
| `dps` | `docker ps` | List running |
| `dpsa` | `docker ps -a` | List all |
| `dimg` | `docker images` | List images |
| `dvol` | `docker volume ls` | List volumes |
| `dnet` | `docker network ls` | List networks |
| `dstop` | `zsh_docker_stop_all` | Stop all containers |
| `dclean` | `docker system prune -af` | Prune everything |
| `drmi` | `zsh_docker_rmi_dangling` | Remove dangling images |
| `drmv` | `zsh_docker_rmv_dangling` | Remove dangling volumes |
| `lzd` | `lazydocker` | Lazydocker TUI |

---

## Node.js

### npm

| Alias | Command | Description |
|-------|---------|-------------|
| `npi` | `npm install` | Install dependencies |
| `npig` | `npm install --global` | Install globally |
| `npid` | `npm install --save-dev` | Install as devDep |
| `nps` | `npm start` | Start |
| `npt` | `npm test` | Test |
| `npr` | `npm run` | Run script |
| `npb` | `npm run build` | Build |
| `npc` | `rm -rf node_modules package-lock.json` | Clean |

### yarn

| Alias | Command | Description |
|-------|---------|-------------|
| `yai` | `yarn install` | Install |
| `yaig` | `yarn global add` | Install globally |
| `yaid` | `yarn add --dev` | Install as devDep |
| `yas` | `yarn start` | Start |
| `yat` | `yarn test` | Test |
| `yar` | `yarn run` | Run script |
| `yab` | `yarn build` | Build |
| `yac` | `rm -rf node_modules yarn.lock` | Clean |

### pnpm

| Alias | Command | Description |
|-------|---------|-------------|
| `pni` | `pnpm install` | Install |
| `pnig` | `pnpm add --global` | Install globally |
| `pnid` | `pnpm add --save-dev` | Install as devDep |
| `pns` | `pnpm start` | Start |
| `pnt` | `pnpm test` | Test |
| `pnr` | `pnpm run` | Run script |
| `pnb` | `pnpm build` | Build |
| `pnc` | `rm -rf node_modules pnpm-lock.yaml` | Clean |

---

## Python

| Alias | Command | Description |
|-------|---------|-------------|
| `py` | `python3` | Python interpreter |
| `python` | `python3` | Python interpreter |
| `pip` | `pip3` | Package manager |
| `venv` | `python3 -m venv` | Create virtualenv |
| `activate` | `zsh_activate_venv` | Activate nearest venv |

---

## Homebrew (macOS)

| Alias | Command | Description |
|-------|---------|-------------|
| `brewup` | `brew update && upgrade && cleanup` | Update all |
| `brewclean` | `brew cleanup --prune=all && autoremove` | Clean up |
| `brewdoctor` | `brew doctor` | Check system |
| `brewdeps` | `brew deps --tree --installed` | Dependency tree |
| `brewleaves` | `brew leaves` | No dependents |
| `brewoutdated` | `brew outdated` | Outdated packages |

---

## System & Network

| Alias | Command | Description |
|-------|---------|-------------|
| `psg` | `ps aux \| grep` | Search processes |
| `pskill` | `zsh_pskill` | Kill by name |
| `ka` | `killall` | Kill all by name |
| `timeout` | `zsh_timeout` | Run with time limit |
| `ports` | `zsh_show_ports` | Show listening ports |
| `ip` | `zsh_publicip` | Public IP |
| `localip` | `zsh_localip` | Local IP |
| `speedtest` | `zsh_speedtest` | Internet speed |
| `portcheck` | `zsh_portcheck` | Check if port open |
| `waitport` | `zsh_waitport` | Wait for port |
| `p8` | `ping -c 5 8.8.8.8` | Quick ping test |

---

## macOS Specific

| Alias | Command | Description |
|-------|---------|-------------|
| `showfiles` | Show hidden files in Finder |
| `hidefiles` | Hide hidden files in Finder |
| `o` | `open` | Open file/folder |
| `o.` | `open .` | Open current dir |
| `ql` | `qlmanage -p` | Quick Look |
| `flushdns` | Flush DNS cache |
| `lock` | Lock screen |
| `afk` | Start screensaver |
| `killapp` | `zsh_killapp` | Kill app by name |
| `pbp` | `pbpaste` | Paste from clipboard |
| `pbc` | `pbcopy` | Copy to clipboard |
| `wifi-scan` | Scan WiFi networks |
| `wifi-info` | WiFi connection info |
| `wifi-name` | Current WiFi name |
| `wifi-pass` | WiFi password |
| `eject` | Eject disk |

---

## Linux Specific

### Package Managers

**apt (Debian/Ubuntu):**

| Alias | Command | Description |
|-------|---------|-------------|
| `apt-up` | `apt update && upgrade` | Update all |
| `apt-clean` | `apt autoremove && autoclean` | Clean up |
| `apt-search` | `apt-cache search` | Search packages |

**dnf (Fedora):**

| Alias | Command | Description |
|-------|---------|-------------|
| `dnf-up` | `dnf upgrade -y` | Update all |
| `dnf-clean` | `dnf autoremove && clean all` | Clean up |

**pacman (Arch):**

| Alias | Command | Description |
|-------|---------|-------------|
| `pac-up` | `pacman -Syu` | Update all |
| `pac-clean` | `pacman -Sc` | Clean cache |
| `yay-up` | `yay -Syu` | AUR update |

### Systemd

| Alias | Command | Description |
|-------|---------|-------------|
| `sc` | `systemctl` | Systemctl |
| `scu` | `systemctl --user` | User services |
| `scstart` | `systemctl start` | Start service |
| `scstop` | `systemctl stop` | Stop service |
| `screstart` | `systemctl restart` | Restart service |
| `scstatus` | `systemctl status` | Service status |

### Journalctl

| Alias | Command | Description |
|-------|---------|-------------|
| `jctl` | `journalctl` | Journal |
| `jctlf` | `journalctl -f` | Follow journal |
| `jctlu` | `journalctl --user` | User journal |

---

## Productivity

| Alias | Command | Description |
|-------|---------|-------------|
| `zshrc` | Edit `.zshrc` |
| `zshenv` | Edit `.zshenv` |
| `gitconfig` | Edit git config |
| `e` | `$EDITOR` | Open in editor |
| `et` | `$TERMINAL_EDITOR` | Terminal editor |
| `reload` | `exec zsh` | Restart shell |
| `src` | `source .zshrc` | Reload config |
| `now` | Current datetime |
| `nowdate` | Current date |
| `nowtime` | Current time |
| `week` | Week number |
| `calc` | Calculator |
| `weather` | Weather forecast |

---

## Global Aliases

Expand anywhere in command line:

| Alias | Expansion | Description |
|-------|-----------|-------------|
| `G` | `\| grep` | Pipe to grep |
| `L` | `\| less` | Pipe to less |
| `H` | `\| head` | Pipe to head |
| `T` | `\| tail` | Pipe to tail |
| `S` | `\| sort` | Pipe to sort |
| `U` | `\| uniq` | Pipe to uniq |
| `C` | `\| wc -l` | Count lines |
| `F` | `\| fzf` | Pipe to fzf |
| `NE` | `2>/dev/null` | Suppress errors |
| `NUL` | `>/dev/null 2>&1` | Suppress all |
| `ERR` | `2>&1` | Stderr to stdout |
| `JQ` | `\| jq` | Pipe to jq |

**Example:**
```bash
ps aux G nginx      # Same as: ps aux | grep nginx
cat file.txt H 20   # Same as: cat file.txt | head 20
```

---

## Suffix Aliases

Files auto-open in editor by extension:

- Text: `.txt`, `.md`, `.rst`
- Config: `.json`, `.yml`, `.yaml`, `.toml`, `.ini`, `.conf`
- Code: `.py`, `.js`, `.ts`, `.go`, `.rs`, `.java`, `.c`, `.cpp`
- Web: `.html`, `.css`, `.scss`

**Example:**
```bash
./README.md         # Opens in $EDITOR
./config.yaml       # Opens in $EDITOR
```
