# PATH Module

Intelligent PATH management with platform-specific optimizations, minimal SSH mode, and comprehensive development tool support.

## Features

### Smart Path Management

- **Duplicate Removal** - Automatically removes duplicate PATH entries
- **Existence Checking** - Only adds directories that actually exist
- **Position Control** - Prepend or append paths as needed
- **Data-Driven** - All paths defined in a structured associative array

### Cross-Platform Support

- **macOS** - Homebrew (Intel & Apple Silicon), MacPorts, Xcode tools, app bundles
- **Linux** - Snap, Flatpak, AppImage, Linuxbrew, Nix, distribution-specific paths
- **BSD** - Ports and pkg paths
- **Auto-Detection** - Platform paths only added when relevant

### Minimal Mode

Reduces PATH complexity in constrained environments:

- **SSH Detection** - Automatically uses minimal PATH in SSH sessions
- **Docker/CI Aware** - Detects containerized environments
- **Configurable** - Can force minimal mode or disable SSH detection

### Development Tools

Automatic detection and PATH configuration for:

| Category | Tools |
|----------|-------|
| **JavaScript** | Volta, NVM, npm, yarn, pnpm, Bun, Deno |
| **Python** | pyenv, Poetry, Rye, pipx |
| **Ruby** | rbenv, RVM, gem |
| **Go** | GOPATH, standard locations |
| **Rust** | Cargo |
| **Java/JVM** | JAVA_HOME, SDKMAN, JBang, jEnv |
| **PHP** | Composer, phpenv |
| **Other** | Julia, Haskell (GHCup, Cabal), Nim, .NET, Dart, Zig |
| **DevOps** | asdf, tfenv |
| **Containers** | Docker, Podman, Colima, Rancher Desktop |
| **Cloud** | AWS Amplify, Google Cloud SDK, Azure CLI, OCI, IBM Cloud |
| **Kubernetes** | Krew, kubectx |
| **Infrastructure** | Pulumi, Terraform |

### IDE Integration

Automatically adds CLI tools from:

- VS Code, VS Code Insiders, VSCodium
- Cursor, Windsurf
- Sublime Text, Nova
- JetBrains Toolbox
- Atom, Zed

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `path_show` | `path`, `pathshow` | Display numbered PATH entries |
| `path_which <cmd>` | `pathwhich` | Find which PATH entry provides a command |
| `path_debug` | `pathdebug` | Show PATH statistics and diagnostics |
| `_path_clean` | `pathclean` | Remove non-existent directories |
| `path_invalid` | `pathinvalid` | Show non-existent PATH entries |
| `path_contains <dir>` | `pathcontains` | Check if PATH contains directory |
| `path_reload` | `pathreload` | Reload PATH from definitions |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_PATH_ENABLED` | `true` | Enable/disable path management |
| `ZSH_PATH_HOMEBREW` | `true` | Detect and initialize Homebrew |
| `ZSH_PATH_CLEAN` | `true` | Remove non-existent directories |
| `ZSH_PATH_PROJECT_BIN` | `false` | Add project-local bin directories |
| `ZSH_PATH_SSH_MINIMAL` | `true` | Use minimal PATH in SSH sessions |
| `ZSH_PATH_FORCE_MINIMAL` | `false` | Force minimal PATH always |

## Project-Local Binaries

When enabled (`ZSH_PATH_PROJECT_BIN=true`), automatically adds these directories when you `cd`:

- `./bin` - Generic project binaries
- `./node_modules/.bin` - Node.js executables
- `./.venv/bin` - Python virtual environments
- `./vendor/bin` - PHP Composer binaries

**Security Note:** Disabled by default as it can execute untrusted code.

## Usage Examples

```bash
# Show current PATH entries (numbered)
path
# Output:
#   1: /opt/homebrew/bin
#   2: /usr/local/bin
#   3: /usr/bin
#   ...

# Find where a command comes from
pathwhich npm
# Output:
#   Command 'npm' found at: /Users/you/.volta/bin/npm
#   From PATH entry: /Users/you/.volta/bin

# Debug PATH issues
pathdebug
# Shows:
#   Total entries: 45
#   Unique entries: 42
#   Non-existent: 3

# Remove non-existent paths
pathclean
# Output: ✓ PATH cleaned

# Check if path contains directory
pathcontains /opt/homebrew/bin
# Output: ✓ Found at position 1
```

## How It Works

### Data-Driven Definitions

All paths are defined in `ZSH_PATH_DEFINITIONS` with conditions:

```zsh
ZSH_PATH_DEFINITIONS=(
    'js_volta'          '$VOLTA_HOME/bin:prepend:if_var_set:VOLTA_HOME'
    'mac_homebrew_m1'   '/opt/homebrew/bin:prepend:if_command_exists:/opt/homebrew/bin/brew'
    'linux_snap'        '/snap/bin:append:os_is_linux'
)
```

Format: `name => "path:position:condition[:value]"`

### Condition Types

| Condition | Description |
|-----------|-------------|
| `always` | Always add |
| `exists` | Add if path exists |
| `if_var_set:VAR` | Add if environment variable is set |
| `if_var_true:VAR` | Add if variable equals "true" |
| `if_command_exists:cmd` | Add if command exists |
| `os_is_darwin` | Add on macOS only |
| `os_is_linux` | Add on Linux only |
| `not_minimal_mode` | Skip in minimal/SSH mode |

### Position

| Position | Effect |
|----------|--------|
| `prepend` | Add at beginning (higher priority) |
| `append` | Add at end (lower priority) |

## Platform-Specific Paths

### macOS

```
/opt/homebrew/bin              # Homebrew (Apple Silicon)
/opt/homebrew/sbin
/usr/local/bin                 # Homebrew (Intel)
/usr/local/sbin
/opt/local/bin                 # MacPorts
/System/Cryptexes/App/usr/bin  # System cryptexes
/Library/Apple/usr/bin         # Apple tools
/Applications/Xcode.app/.../bin # Xcode
/Library/Developer/CommandLineTools/usr/bin
```

### Linux

```
/snap/bin                      # Snap packages
/var/lib/flatpak/exports/bin   # Flatpak (system)
~/.local/share/flatpak/...     # Flatpak (user)
~/Applications                 # AppImages
~/.nix-profile/bin             # Nix
/home/linuxbrew/.linuxbrew/bin # Linuxbrew
/usr/games
```

## Minimal Mode Detection

Minimal mode activates when:

1. `ZSH_PATH_FORCE_MINIMAL=true`
2. SSH session detected (`$SSH_CONNECTION` set) and `ZSH_PATH_SSH_MINIMAL=true`
3. Running in Docker/CI (detected via `/.dockerenv`, `CI` variable)

In minimal mode, many development tool paths are skipped for faster startup.

## Load Order

The PATH module loads **last** in `.zshenv` to ensure it can enhance PATH after all other environment setup.
