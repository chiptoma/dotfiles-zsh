# Keybindings Module

Final keybinding configuration that loads last to override plugin defaults.

## Overview

The keybindings module ensures consistent key behavior by loading **after** all plugins (autosuggestions, fzf, fzf-tab, etc.). This prevents plugins from overriding your preferred bindings.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `Z_KEYBINDINGS_ENABLED` | `true` | Enable/disable keybindings module |

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

Provided by the vendored `dirhistory` widget (`lib/plugins/vendor/dirhistory.zsh`, loaded automatically):

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

The module specifically fixes a common issue where fzf's shell bindings override atuin's up-arrow binding. After loading all plugins, this module re-binds the arrow keys to atuin's widgets.

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
3. Source keybindings manually: `source ~/.config/zsh/modules/07_keybindings.zsh`

**Bindings overridden after shell start:**

Some plugins load asynchronously. Add your bindings at the very end of `.zshlocal`.

**Terminal-specific issues:**

Different terminals send different escape sequences. Use `cat` to see what your terminal sends:

```bash
cat -v
# Press the key, see the sequence
```

## Load Order

The keybindings module is intentionally the **last module** in `.zshrc`:

1. Plugins load (`lib/plugins/index.zsh`: fzf-tab, autosuggestions, fzf bindings, vendored widgets)
2. Other modules load
3. **Keybindings module loads** (overrides plugin bindings)
4. `.zshlocal` loads (for user overrides)
5. zsh-syntax-highlighting loads last (widget wrapping only — it respects existing bindings)

## Dependencies

- **Optional:** atuin (for enhanced history search)
- **Bundled:** `dirhistory` vendored widget (for Alt+arrow navigation)
