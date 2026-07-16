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
   ./tests/unit-test.zsh
   ./tests/smoke-test.zsh
   shellcheck install.sh
   ```
5. **Update documentation** if your change affects usage
6. **Submit a PR** with:
   - Clear description of the change
   - Link to any related issues
   - Screenshots/recordings for UI changes

## Testing

### Running Tests

```bash
# Unit tests
./tests/unit-test.zsh

# Verbose mode
./tests/unit-test.zsh --verbose

# Smoke tests (requires zsh config installed)
./tests/smoke-test.zsh
```

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

Tests run automatically on:
- Ubuntu 22.04
- Fedora (latest)
- Arch Linux (latest)
- macOS (latest)

## Development Setup

```bash
# Clone the repo
git clone https://github.com/chiptoma/dotfiles-zsh.git
cd dotfiles-zsh

# Install for development (symlink mode)
./install.sh  # Choose option 1 (Symlink)

# Make changes to files in the repo
# Changes reflect immediately in your shell
```

## Architecture Overview

```
.
├── install.sh              # Main installer script
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
│   ├── utils/              # Utility functions
│   │   ├── core.zsh        # _has_cmd, _cache_eval, etc.
│   │   ├── logging.zsh     # _log function
│   │   └── platform/       # OS detection & helpers
│   └── functions/          # User-facing functions
├── tests/                  # Test suites
└── docs/                   # Documentation
```

### Module Dependency Graph

Understanding the load order is critical for contributors:

```
┌─────────────────────────────────────────────────────────────┐
│                    LOAD ORDER (.zshenv)                      │
├─────────────────────────────────────────────────────────────┤
│  1. lib/core/logging.zsh      ← No dependencies             │
│  2. lib/core/helpers.zsh      ← Depends on: logging         │
│  3. lib/core/platform/        ← Depends on: logging, helpers│
│  4. modules/01_path.zsh       ← Depends on: core, platform  │
│  5. modules/02_environment.zsh ← Depends on: core, platform │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    LOAD ORDER (.zshrc)                       │
├─────────────────────────────────────────────────────────────┤
│  1. Oh My Zsh (if enabled)                                  │
│  2. modules/03_lazy.zsh        ← Depends on: core           │
│  3. modules/04_completion.zsh  ← Depends on: core           │
│  4. modules/05_history.zsh     ← Depends on: core           │
│  5. modules/06_aliases.zsh     ← Depends on: core, platform │
│  6. modules/07_keybindings.zsh ← Depends on: core           │
│  7. .zshlocal                  ← User customizations (last) │
└─────────────────────────────────────────────────────────────┘
```

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
