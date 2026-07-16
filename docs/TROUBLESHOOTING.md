# Troubleshooting Guide

Common issues and their solutions.

## Quick Diagnostics

Run these commands first:

```bash
health          # Full configuration health check
status          # Show current configuration state
zbench          # Benchmark startup time
```

---

## Prompt Issues

### Prompt Shows Boxes or Question Marks

**Symptom:** Your prompt displays `?` boxes or `???` instead of icons.

**Cause:** Starship uses Nerd Font glyphs that your terminal font doesn't support.

**Solution:**

1. Install a Nerd Font:
   - Visit [nerdfonts.com](https://www.nerdfonts.com/)
   - Download **JetBrainsMono Nerd Font** (recommended)
   - Install the font on your system

2. Configure your terminal to use the font:
   - **iTerm2:** Preferences > Profiles > Text > Font
   - **Terminal.app:** Preferences > Profiles > Font
   - **VS Code:** Settings > Terminal > Font Family: `"JetBrainsMono Nerd Font"`
   - **Windows Terminal:** Settings > Profiles > Appearance > Font face

3. Restart your terminal

### Prompt Not Showing / Plain Prompt

**Symptom:** You see a basic `%` or `$` prompt instead of the custom Starship prompt.

**Cause:** Starship not installed or not initialized.

**Solution:**

```bash
# Check if starship is installed
command -v starship

# If not installed
./install.sh --tools starship

# If installed but not loading, check .zshlocal
grep starship ~/.config/zsh/.zshlocal
```

The line should be: `eval "$(starship init zsh)"`

---

## Command Not Found

### `ll` / `ls` Shows "Command Not Found"

**Symptom:** Common listing aliases don't work.

**Cause:** `eza` tool not installed.

**Solution:**

```bash
# Install eza
./install.sh --tools eza

# Or use system package manager
brew install eza      # macOS
apt install eza       # Ubuntu 22.10+
```

**Workaround:** The fallback aliases should work even without eza:

```bash
# These always work (use native ls)
ls                    # Basic listing
ls -la                # Long listing
```

### `bat` / `cat` Enhancements Missing

**Symptom:** `cat` doesn't show syntax highlighting.

**Cause:** `bat` not installed.

**Solution:**

```bash
./install.sh --tools bat

# Or manually
brew install bat                    # macOS
apt install bat                     # Ubuntu (installs as 'batcat')
```

**Note:** On Ubuntu, bat is installed as `batcat`. The aliases handle this automatically.

### `z` Directory Jump Not Working

**Symptom:** `z <directory>` does nothing or shows error.

**Cause:** Zoxide not installed or not initialized.

**Solution:**

```bash
# Install zoxide
./install.sh --tools zoxide

# Verify it's in .zshlocal
grep zoxide ~/.config/zsh/.zshlocal
```

Should contain: `eval "$(zoxide init zsh)"`

**Note:** Zoxide needs usage data. It learns from your `cd` commands. Use `cd` normally for a while, then `z` will start working.

---

## Shell Startup Issues

### Shell Starts Slowly (> 500ms)

**Symptom:** New terminal windows take noticeable time to appear.

**Diagnosis:**

```bash
zbench          # Benchmark startup time
```

**Solutions:**

1. **Enable lazy loading** (default):
   ```bash
   # Ensure this is NOT set to false
   export Z_LAZY_ENABLED=true
   ```

2. **Disable unused features**:
   ```bash
   # In ~/.config/zsh/.zshlocal
   export Z_LAZY_NVM=false     # If you don't use nvm
   export Z_LAZY_PYENV=false   # If you don't use pyenv
   ```

3. **Profile the startup**:
   ```bash
   # Quick timing
   time zsh -i -c exit

   # Per-stage breakdown (modules, plugins, registry)
   Z_PROFILE_STARTUP=true zsh -ic z_profile

   # Function-level (zprof) report
   Z_PROFILE_STARTUP=zprof zsh -ic exit
   ```

### Shell Crashes on Startup

**Symptom:** Terminal closes immediately or shows errors.

**Recovery:**

```bash
# Start zsh without loading config
zsh -f

# Check for syntax errors
zsh -n ~/.config/zsh/.zshrc

# Reset to defaults
mv ~/.config/zsh/.zshlocal ~/.config/zsh/.zshlocal.backup
exec zsh
```

### "ZDOTDIR points to different location" Error

**Symptom:** Installer refuses to continue.

**Cause:** You have an existing ZDOTDIR set elsewhere.

**Solution:**

1. Check current ZDOTDIR:
   ```bash
   echo $ZDOTDIR
   ```

2. Either:
   - Remove the conflicting ZDOTDIR from `~/.zshenv` or `~/.zprofile`
   - Or install to the existing ZDOTDIR location

---

## History Issues

### History Not Saving

**Symptom:** Commands disappear after closing terminal.

**Cause:** History file permissions or location issues.

**Solution:**

```bash
# Check history file exists
ls -la ~/.local/share/zsh/history

# Check permissions
chmod 600 ~/.local/share/zsh/history

# Verify HISTFILE is set
echo $HISTFILE
```

### Sensitive Commands Appearing in History

**Symptom:** Passwords or API keys visible in history.

**Solution:** Security filtering should be automatic. Verify:

```bash
# Commands starting with space are not saved
 echo "secret"   # Note the leading space

# These patterns are auto-filtered:
# - Lines with password/secret/token/key followed by =
# - AWS credentials
# - API keys
```

To manually clean history:

```bash
hist-clean      # Interactive cleanup
```

---

## Completion Issues

### Tab Completion Not Working

**Symptom:** Tab does nothing or shows basic completion.

**Cause:** Completion system not initialized.

**Solution:**

```bash
# Force completion rebuild
rm ~/.cache/zsh/completion/zcompdump*
exec zsh
```

### Completion Very Slow

**Symptom:** Tab completion hangs for seconds.

**Solution:**

```bash
# Rebuild completion cache
compinit -C

# Check completion TTL
echo $Z_COMPLETION_TTL   # Should be 86400 (24h)
```

---

## Platform-Specific Issues

### macOS: Homebrew Commands Not Found

**Symptom:** `brew` or Homebrew-installed tools not in PATH.

**Solution:**

```bash
# Apple Silicon Macs
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel Macs
eval "$(/usr/local/bin/brew shellenv)"
```

Add to `~/.config/zsh/.zshlocal` if not automatically detected.

### Linux: Tools Installed as Different Names

**Symptom:** `bat` installed but `bat` command not found.

**Cause:** Ubuntu/Debian use `batcat` and `fdfind` to avoid name conflicts.

**Solution:** The aliases should handle this automatically. If not:

```bash
# In ~/.config/zsh/.zshlocal
[[ -x /usr/bin/batcat ]] && alias bat='batcat'
[[ -x /usr/bin/fdfind ]] && alias fd='fdfind'
```

### WSL: Slow Performance

**Symptom:** Shell is sluggish under Windows Subsystem for Linux.

**Solutions:**

1. Keep files on Linux filesystem (not `/mnt/c/`)
2. Disable git status in prompt:
   ```bash
   # In ~/.config/starship.toml
   [git_status]
   disabled = true
   ```

---

## SSH Issues

### "Too many authentication failures"

The SSH agent (typically 1Password) offers **every** enabled key to every
server, one per authentication attempt. Servers reject the connection after
`MaxAuthTries` attempts (OpenSSH default: 6), so with 6+ keys in the agent,
hosts whose key sits late in the offer order never get it.

Check how many keys your agent offers:

```bash
sshagent          # provider, socket, liveness, key count (z_ssh_agent)
ssh-add -l | wc -l
```

Fixes, in order of preference:

1. **1Password SSH bookmarks (best)** — add a URL field `ssh://user@host`
   to each SSH key item (or click *Bookmark* in 1Password → SSH Agent →
   Activity after connecting once). 1Password then generates
   `~/.ssh/1Password/config` with exact host-to-key `Match` blocks.
   Activate it once by putting this as the FIRST line of `~/.ssh/config`:

   ```
   Include ~/.ssh/1Password/config
   ```

2. **Pin hosts manually** in `~/.ssh/config` — offer exactly one key:

   ```
   Host myserver
       IdentityFile ~/.ssh/mykey.pub
       IdentitiesOnly yes
   ```

3. **Order and trim the agent** in `~/.config/1Password/ssh/agent.toml` —
   the order of `[[ssh-keys]]` entries is the offer order; put your
   most-used key/vault first and remove vaults never used for SSH.
   Changes apply live, no restart needed.

Do **not** set `IdentitiesOnly yes` under a bare `Host *` — hosts without
an `IdentityFile` would then offer no keys at all.

### Auto-accepting new host keys

The agent never manages `known_hosts`. To stop first-connection prompts
while still rejecting *changed* keys (MITM protection), add to `~/.ssh/config`:

```
Host *
    StrictHostKeyChecking accept-new
```

### Stale agent socket

`SSH_AUTH_SOCK` points at a socket file that exists but nothing answers
(app quit, machine slept). Diagnose with `sshagent`; fix by starting the
agent app and opening a new shell (or running `_detect_ssh_agent`).

## Configuration Issues

### Changes to .zshlocal Not Taking Effect

**Symptom:** Edits to `.zshlocal` don't appear in new terminals.

**Solution:**

```bash
# Reload configuration
exec zsh

# Or source directly
source ~/.config/zsh/.zshlocal
```

### "No such file or directory" for Modules

**Symptom:** Errors about missing module files.

**Cause:** Incomplete installation or corrupted files.

**Solution:**

```bash
# Verify installation
./install.sh --check

# Reinstall if needed
./install.sh --yes
```

---

## Debugging Guide

### Enable Debug Logging

The framework has a built-in logging system with levels: `DEBUG`, `INFO`, `WARN`, `ERROR`, `NONE`.

```bash
# Temporary: see all module loading for one session
Z_LOG_LEVEL=DEBUG exec zsh

# Persistent: add to .zshlocal
echo 'export Z_LOG_LEVEL=DEBUG' >> ~/.config/zsh/.zshlocal
exec zsh
```

Debug output shows: timestamp, level, source file, function name, and message. Example:
```
[+2025-01-15 10:32:01] [DEBUG] [path.zsh:_path_add:42]: Adding /opt/homebrew/bin
[+2025-01-15 10:32:01] [DEBUG] [lazy.zsh:_lazy_init_zoxide:85]: Deferred zoxide init
```

### Test Individual Modules

You can source and test any module in isolation:

```bash
# Start a clean shell
zsh -f

# Load just the core utilities
source ~/.config/zsh/.zshenv

# Now test a specific module
source ~/.config/zsh/modules/05_history.zsh
echo $HISTFILE   # Should be set

# Or test a function library
source ~/.config/zsh/lib/functions/utilities.zsh
z_calc 2+2       # Should output 4
```

### Run the Test Suite

All test layers run through the Justfile (see [TESTING.md](TESTING.md)):

```bash
cd ~/.config/zsh
just test          # Lint + unit + smoke
just test-unit     # Unit suite only
just test-smoke    # Smoke suite only
```

### Common Debug Scenarios

**Which modules loaded?**
```bash
# Check idempotent guard variables
Z_LOG_LEVEL=DEBUG zsh -ic 'print -l ${(k)parameters[(I)_Z_*_LOADED]}; exit'
```

**What's in my PATH?**
```bash
zpath         # Pretty-printed list
zpathdebug    # Full diagnostics with conditions
```

**What did lazy loading defer?**
```bash
lazy          # Show status of all lazy-loaded tools
```

**Is a tool being detected?**
```bash
# Check if a command is in the hash table
(( $+commands[starship] )) && echo "found" || echo "not found"
```

---

## Getting Help

### Built-in Commands

```bash
help            # Quick reference guide
zstatus         # Show current configuration
zhealth         # Diagnostic health check
als             # Browse all aliases
```

### Resources

- **Documentation:** `~/.config/zsh/docs/`
- **Source code:** `~/.config/zsh/`
- **Issues:** [GitHub Issues](https://github.com/chiptoma/dotfiles-zsh/issues)

### Reporting Issues

When reporting issues, include:

```bash
# System info
uname -a
echo $SHELL
echo $ZSH_VERSION

# Configuration check
./install.sh --check

# Health status
zhealth

# Relevant error messages
```
