# Keybindings Module

Final keybinding configuration that loads last to override plugin defaults.

## Overview

The keybindings module ensures consistent key behavior by loading **after** all plugins (Oh My Zsh, fzf, etc.). This prevents plugins from overriding your preferred bindings.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_KEYBINDINGS_ENABLED` | `true` | Enable/disable keybindings module |

## Key Bindings

### History Search (Atuin)

If [atuin](https://atuin.sh/) is installed:

| Key | Action |
|-----|--------|
| `↑` (Up Arrow) | Atuin history search |
| `↓` (Down Arrow) | Atuin history navigation |

**Note:** Both escape sequences are bound to handle different terminal modes:
- `^[[A` / `^[[B` - Raw/normal mode
- `^[OA` / `^[OB` - Application cursor mode

### Directory Navigation

If the `dirhistory` Oh My Zsh plugin is loaded:

| Key | Action |
|-----|--------|
| `Alt+↑` | Go to previous directory |
| `Alt+↓` | Go to next directory |

Works like browser back/forward for directories.

### Line Editing

| Key | Action |
|-----|--------|
| `Ctrl+Backspace` | Delete word backward |
| `Ctrl+Delete` | Delete word forward |
| `Home` | Beginning of line |
| `End` | End of line |

**Cross-platform Home/End:**
- `^[[H` / `^[[F` - Most terminals
- `^[[1~` / `^[[4~` - Linux console

## Atuin Integration

The module specifically fixes a common issue where Oh My Zsh or fzf plugins override atuin's up-arrow binding. After loading all plugins, this module re-binds the arrow keys to atuin's widgets.

### Checking Atuin Status

```bash
# Verify atuin bindings are active
bindkey | grep atuin

# Should show:
# "^[[A" atuin-up-search
# "^[OA" atuin-up-search
```

### Manual Binding (if needed)

If bindings aren't working, add to `.zshlocal`:

```bash
bindkey '^[[A' atuin-up-search
bindkey '^[OA' atuin-up-search
```

## Customization

### Adding Custom Bindings

Add to `.zshlocal`:

```bash
# Bind Ctrl+G to git status
bindkey -s '^G' 'git status^M'

# Bind Ctrl+F to fzf file search
bindkey -s '^F' 'fzf^M'
```

### Viewing Current Bindings

```bash
# List all bindings
bindkey

# Search for specific binding
bindkey | grep -i arrow

# Show what a key does
bindkey '^[[A'
```

### Escape Sequence Reference

Common escape sequences:

| Sequence | Key |
|----------|-----|
| `^[` | Alt/Meta prefix (or Escape) |
| `^[[A` | Up arrow |
| `^[[B` | Down arrow |
| `^[[C` | Right arrow |
| `^[[D` | Left arrow |
| `^[[H` | Home |
| `^[[F` | End |
| `^[[3~` | Delete |
| `^H` | Ctrl+Backspace |
| `^?` | Backspace |

## Troubleshooting

**Arrow keys not working with atuin:**

1. Verify atuin is installed: `which atuin`
2. Check widget exists: `bindkey | grep atuin`
3. Source keybindings manually: `source ~/.config/zsh/modules/keybindings.zsh`

**Bindings overridden after shell start:**

Some plugins load asynchronously. Add your bindings at the very end of `.zshlocal`.

**Terminal-specific issues:**

Different terminals send different escape sequences. Use `cat` to see what your terminal sends:

```bash
cat -v
# Press the key, see the sequence
```

## Load Order

The keybindings module is intentionally loaded **last** in `.zshrc`:

1. Oh My Zsh plugins load
2. fzf bindings load
3. Other modules load
4. **Keybindings module loads** (overrides all)
5. `.zshlocal` loads (for user overrides)

## Dependencies

- **Optional:** atuin (for enhanced history search)
- **Optional:** Oh My Zsh dirhistory plugin (for Alt+arrow navigation)
