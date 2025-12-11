# Compilation Module

Automatic ZSH bytecode compilation for faster shell startup.

## Overview

ZSH can compile scripts to bytecode (`.zwc` files) for faster loading. This module automatically compiles your configuration files and keeps the compiled versions up to date.

## How It Works

1. **Source Detection** - Scans for `.zsh` files in config directories
2. **Incremental Compilation** - Only recompiles when source is newer
3. **Directory Archives** - Bundles function directories into single `.zwc` files
4. **Stale Cleanup** - Removes orphaned `.zwc` files automatically

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_COMPILATION_ENABLED` | `false` | Enable/disable compilation |
| `ZSH_COMPILATION_CLEANUP_ON_START` | `true` | Remove stale `.zwc` on startup |

**Note:** Compilation is **disabled by default**. Enable it for faster startup on slower systems.

## Enable Compilation

Add to `.zshlocal`:

```bash
export ZSH_COMPILATION_ENABLED=true
```

Then restart your shell or run:

```bash
source ~/.config/zsh/modules/compilation.zsh
```

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `zsh_cleanup_zwc` | `compclean` | Remove stale `.zwc` files |
| `zsh_cleanup_zwc all` | `compclean-all` | Remove ALL `.zwc` files |

## What Gets Compiled

### Core Files

- `~/.config/zsh/.zshrc`
- `~/.config/zsh/.zshenv`
- `~/.config/zsh/.zprofile`
- `~/.config/zsh/.zlogin`
- `~/.config/zsh/.zlogout`
- `~/.p10k.zsh` (if using Powerlevel10k)

### Module Files

- All `.zsh` files in `modules/`
- All `.zsh` files in `lib/`

### Function Directories

Function directories are compiled into a single archive:

```
lib/functions/          →  lib/functions.zwc
├── system.zsh
├── file.zsh
├── git.zsh
└── ...
```

This is more efficient than compiling each file separately.

## Performance Impact

Typical improvements on cold shell start:

| System | Without `.zwc` | With `.zwc` | Improvement |
|--------|---------------|-------------|-------------|
| Fast SSD | 150ms | 120ms | ~20% |
| Slow HDD | 400ms | 250ms | ~38% |
| Raspberry Pi | 800ms | 500ms | ~38% |

**Note:** On modern NVMe drives, the improvement may be marginal.

## How ZSH Uses .zwc Files

When ZSH sources a file:

1. Checks if `filename.zwc` exists
2. If `.zwc` is newer than source, loads bytecode
3. Otherwise, parses source file normally

ZSH automatically prefers `.zwc` files when present.

## Stale File Cleanup

A `.zwc` file becomes "stale" when:
- The source file was deleted
- The source file was renamed

Stale cleanup (runs on shell start if enabled):

```bash
# Manual cleanup
compclean

# Nuclear option - remove all compiled files
compclean-all
```

## Debug Mode

See all compiled files:

```bash
export ZSH_COMPILATION_DEBUG=true
exec zsh
```

Output shows:
```
Compiled files list:
  -> .config/zsh/.zshrc.zwc
  -> .config/zsh/modules/aliases.zsh.zwc
  -> .config/zsh/lib/functions.zwc
  -> Total: 15 compiled files
```

## Troubleshooting

### Changes Not Taking Effect

If you edit a file but see old behavior:

```bash
# Remove compiled version of specific file
rm ~/.config/zsh/modules/aliases.zsh.zwc

# Or remove all and let them regenerate
compclean-all
```

### Permission Errors

Compilation requires write access to the directory containing the source file:

```bash
# Check permissions
ls -la ~/.config/zsh/

# Fix if needed
chmod 755 ~/.config/zsh/
```

### Syntax Errors

If a file has syntax errors, `zcompile` will fail silently. Check with:

```bash
zsh -n ~/.config/zsh/modules/problem-file.zsh
```

## When to Disable

Consider disabling compilation if:

- You're actively developing your ZSH config
- You have a fast NVMe drive (minimal benefit)
- You're experiencing weird behavior after changes

## Technical Details

### Function Directory Compilation

The module uses `zcompile` with multiple source files:

```bash
zcompile output.zwc file1.zsh file2.zsh file3.zsh
```

This creates a single archive containing all functions, which is faster to load than individual files.

### Compilation Check

Before compiling, the module checks if the source is newer:

```bash
[[ ! -f "$compiled" || "$src" -nt "$compiled" ]]
```

This ensures unnecessary recompilation doesn't happen.

### File Locations

| Type | Location |
|------|----------|
| Config `.zwc` | Same directory as source |
| Function archive | Parent directory (e.g., `lib/functions.zwc`) |
