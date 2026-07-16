# Contributing to ZSH Dotfiles

Thank you for considering contributing to this project!

## Code Style

### Shell Scripts (Bash/ZSH)
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use `snake_case` for function and variable names
- Quote all variables: `"$var"` not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use `$(command)` for substitution, not backticks

### Semantic Comment Prefixes
All comments should use these prefixes for visual consistency:
```bash
# SECTION TITLE     - Green: Headers, function names
# Description       - Blue: Explanations, notes
# WARNING           - Red: Critical warnings, deprecations
# TODO: Action item   - Orange: Tasks to complete
```

### File Headers
Files over 20 lines should have a banner:
```bash
# ==============================================================================
# FILE TITLE
# Purpose: Brief description of this file's role.
# ==============================================================================
```

## Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short description

Optional longer description.
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `test` - Adding or updating tests
- `chore` - Maintenance tasks
- `ci` - CI/CD changes

**Examples:**
```
feat(installer): add essential/recommended tool tiers
fix(tools): handle missing unzip for yazi installation
docs(readme): add installation demo gif
test(integration): add repair command test cases
```

## Pull Request Process

1. **Fork** the repository
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feat/my-feature
   ```
3. **Make your changes** with clear, atomic commits
4. **Run tests locally:**
   ```bash
   just test    # lint + unit + smoke (L0-L2)
   ```
5. **Update documentation** if your change affects usage
6. **Submit a PR** with:
   - Clear description of the change
   - Link to any related issues
   - Screenshots/recordings for UI changes

## Testing

All testing runs through the [Justfile](Justfile) — see [docs/TESTING.md](docs/TESTING.md) for the full layer breakdown (L0 lint → L5 CI).

### Running Tests

```bash
just test               # L0 lint + L1 unit + L2 smoke — the default local gate
just lint               # Syntax checks, shellcheck, structure + help-sync tests
just test-unit          # Unit suite only
just test-smoke         # Smoke suite only
just test-docker fedora # Installer + unit + smoke inside a distro container
just test-all           # Everything runnable locally (L0-L4, needs Docker)
```

`just test-install` mutates `$HOME` and refuses to run outside a container — use `just test-docker <distro>` instead, or `FORCE=1` on a throwaway machine.

### Writing Tests

Add tests to `tests/unit-test.zsh` using the existing framework:

```bash
test_my_feature() {
    # Setup
    local input="test"

    # Execute
    local result=$(my_function "$input")

    # Assert
    assert_eq "$result" "expected" "my_function handles input"
}
```

### CI Environment

Tests run automatically on push/PR:
- Quality workflow: `just lint`, `just test-unit`, `just test-smoke` on Ubuntu
- Platform matrix: Ubuntu (22.04/24.04), Debian, Fedora, Arch, Alpine, Rocky, openSUSE, macOS, simulated WSL

## Development Setup

```bash
# Clone the repo
git clone https://github.com/chiptoma/dotfiles-zsh.git
cd dotfiles-zsh

# Install for development (symlink mode)
./install.sh --symlink

# Make changes to files in the repo
# Changes reflect immediately in your shell
```

## Architecture Overview

```
.
├── install.sh              # Main installer script
├── Justfile                # Task runner (dev/test/maintenance)
├── .zshrc                  # Shell entry point (interactive)
├── .zshenv                 # Environment variables (all shells)
├── modules/                # Feature modules (numbered by load order)
│   ├── 01_path.zsh         # PATH management
│   ├── 02_environment.zsh  # Environment setup
│   ├── 03_lazy.zsh         # Deferred tool initialization
│   ├── 04_completion.zsh   # Tab completion
│   ├── 05_history.zsh      # History configuration
│   ├── 06_aliases.zsh      # Command aliases
│   └── 07_keybindings.zsh  # Key mappings
├── lib/                    # Shared libraries
│   ├── core/               # Foundational infrastructure
│   │   ├── logging.zsh     # _log function
│   │   ├── ui.zsh          # Shared output helpers
│   │   ├── helpers.zsh     # _has_cmd, _cache_eval, etc.
│   │   ├── profile.zsh     # Opt-in startup profiler
│   │   └── platform/       # OS detection & helpers
│   ├── functions/          # User-facing z_* functions
│   ├── plugins/            # Plugin loader + vendored widgets
│   └── registry/           # Tool knowledge (paths, env, tools.dat)
├── tools/                  # Shipped tool configs (manifest.dat)
├── ansible/                # Ansible role + playbook
├── tests/                  # Test suites
└── docs/                   # Documentation
```

### Module Dependency Graph

Understanding the load order is critical for contributors:

```
┌─────────────────────────────────────────────────────────────┐
│                    LOAD ORDER (.zshenv)                      │
├─────────────────────────────────────────────────────────────┤
│  1. lib/core/profile.zsh       ← Opt-in startup profiler    │
│  2. lib/core/index.zsh         ← logging → ui → helpers →   │
│                                  platform                   │
│  3. lib/functions/index.zsh    ← Depends on: core           │
│  4. lib/registry/index.zsh     ← Depends on: core           │
│  5. modules/01_path.zsh        ← Depends on: core, registry │
│  6. modules/02_environment.zsh ← Depends on: core, registry,│
│                                  path                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    LOAD ORDER (.zshrc)                       │
├─────────────────────────────────────────────────────────────┤
│  1. modules/03_lazy.zsh        ← Depends on: core           │
│  2. modules/04_completion.zsh  ← Depends on: core (compinit)│
│  3. lib/plugins/index.zsh      ← fzf-tab, autosuggestions,  │
│                                  fzf/op init, vendored      │
│                                  widgets                    │
│  4. modules/05_history.zsh     ← Depends on: core           │
│  5. modules/06_aliases.zsh     ← Depends on: core, platform │
│  6. modules/07_keybindings.zsh ← Depends on: core, plugins  │
│  7. post-interactive hooks     ← starship init, path clean  │
│  8. .zshlocal                  ← User customizations        │
│  9. zsh-syntax-highlighting    ← LAST (binds ZLE widgets    │
│                                  over everything)           │
└─────────────────────────────────────────────────────────────┘
```

### Naming Conventions

Every symbol follows exactly one of these patterns — the drift tests enforce it:

| Kind | Convention | Example |
|------|------------|---------|
| User-tunable setting (exported) | `Z_*` | `Z_LOG_LEVEL`, `Z_LAZY_ENABLED` |
| Internal global state | `_Z_*` | `_Z_REGISTRY_LOADED` |
| Registry data table | `Z_*` array | `Z_PATH_DEFINITIONS`, `Z_ENV_TOOLS_*`, `Z_TOOLS` |
| Public command function | `z_*` | `z_health`, `z_log_level`, `z_dotfiles_backup` |
| Internal helper function | `_*` | `_has_cmd`, `_ui_kv`, `_z_tools_load` |
| Module init function | `_<module>_init` | `_path_init`, `_environment_init` |
| Post-interactive hook | `_*_hook` in `Z_POST_INTERACTIVE_HOOKS` | `_xdg_guardian_hook` |
| Module file | `NN_name.zsh` (load order) | `modules/03_lazy.zsh` |
| Registry data file | topic `.zsh` / shared `.dat` | `lib/registry/python.zsh`, `tools.dat` |

**Documented exceptions** (third-party or ecosystem contracts, never rename):
`ZSH_VERSION`, `ZSH_COMPDUMP`, `$ZSH` (legacy Oh My Zsh installs — its completion
dirs are still honored), `ZSH_AUTOSUGGEST_*` (plugin),
and the framework directory quartet `ZSH_CONFIG_HOME`/`ZSH_CACHE_HOME`/
`ZSH_DATA_HOME`/`ZSH_STATE_HOME` (mirrors the XDG naming scheme).

### Key Architectural Rules

1. **No circular dependencies**: Lower-level modules never import higher-level ones
2. **Idempotent loading**: All modules use `(( ${+_GUARD} )) && return 0` pattern
3. **Platform isolation**: Platform-specific code lives in `lib/core/platform/`
4. **Toggle pattern**: Modules check `Z_*_ENABLED` before loading
5. **Security first**: `_cache_eval` allowlists every eval'd tool; history filters sensitive patterns

## Reporting Issues

When reporting bugs, include:
- OS and version (e.g., macOS 14.2, Ubuntu 22.04)
- ZSH version (`zsh --version`)
- Steps to reproduce
- Expected vs actual behavior
- Relevant error messages

## Questions?

Open a [Discussion](https://github.com/chiptoma/dotfiles-zsh/discussions) for:
- Feature requests
- Usage questions
- General feedback
