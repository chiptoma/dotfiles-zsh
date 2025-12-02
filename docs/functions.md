# Functions Library

User-facing utility functions organized by category. All functions use the `zsh_` prefix and are designed for interactive use.

## Function Categories

| Category | File | Description |
|----------|------|-------------|
| System | [lib/functions/system.zsh](../lib/functions/system.zsh) | Calculator, weather, process management |
| File | [lib/functions/file.zsh](../lib/functions/file.zsh) | File operations, archives, navigation |
| Git | [lib/functions/git.zsh](../lib/functions/git.zsh) | Repository maintenance |
| Docker | [lib/functions/docker.zsh](../lib/functions/docker.zsh) | Container cleanup |
| Network | [lib/functions/network.zsh](../lib/functions/network.zsh) | Ports, IPs, connectivity |
| Python | [lib/functions/python.zsh](../lib/functions/python.zsh) | Virtual environment helpers |
| Introspection | [lib/functions/introspection.zsh](../lib/functions/introspection.zsh) | Shell debugging tools |

## System Functions

### `zsh_calc` / `calc`

Calculator using Python for complex expressions.

```bash
calc 2 + 2          # 4
calc "sqrt(16)"     # 4.0
calc "sin(pi/2)"    # 1.0
calc 2**10          # 1024
calc "log(100)"     # 2.0
```

**Features:**
- Supports all Python math functions (`sqrt`, `sin`, `cos`, `tan`, `log`, `exp`, etc.)
- Constants: `pi`, `e`, `tau`
- Operators: `+`, `-`, `*`, `/`, `**` (power), `%` (modulo)

### `zsh_weather` / `weather`

Get weather forecast from wttr.in.

```bash
weather              # Weather for auto-detected location
weather London       # Weather for specific city
weather "New York"   # Multi-word city names
```

### `zsh_timeout`

Run a command with a timeout.

```bash
zsh_timeout 5 long_running_command    # Kill after 5 seconds
zsh_timeout 60 make build             # 60 second timeout
```

### `zsh_pskill`

Interactively kill processes by name using fzf.

```bash
pskill          # Browse all processes
pskill node     # Filter to processes matching "node"
```

**Features:**
- Multi-select with Tab
- Preview shows full process details
- Confirms before killing

## File Functions

### `zsh_sizeof` / `sizeof`

Show size of files or directories.

```bash
sizeof .               # Size of current directory
sizeof file.txt        # Size of single file
sizeof dir1 dir2       # Size of multiple items
```

### `zsh_backup` / `backup`

Create timestamped backup of a file.

```bash
backup config.yaml     # Creates config.yaml.2024-01-15_14-30-45.bak
```

### `zsh_todos` / `todos`

Find TODO/FIXME/HACK comments in files.

```bash
todos                  # Search current directory
todos src/             # Search specific directory
```

**Patterns matched:**
- `TODO:`
- `FIXME:`
- `HACK:`
- `XXX:`

### `zsh_extract` / `extract`

Extract any archive format automatically.

```bash
extract archive.tar.gz
extract file.zip
extract package.7z
```

**Supported formats:**
- `.tar.bz2`, `.tar.gz`, `.tar.xz`, `.tar.zst`, `.tar`
- `.bz2`, `.gz`, `.xz`, `.zst`
- `.zip`, `.rar`, `.7z`
- `.Z`, `.deb`, `.rpm`

### `zsh_yazi` / `y`

File manager with directory change on exit.

```bash
y                      # Open yazi in current directory
y ~/Documents          # Open in specific directory
```

When you quit yazi, your shell `cd`s to the last visited directory.

### `zsh_up` / `up`

Navigate up multiple directories.

```bash
up                     # Go up 1 level (cd ..)
up 3                   # Go up 3 levels
up 5                   # Go up 5 levels
```

### `zsh_mkcd` / `mkcd`

Create directory and cd into it.

```bash
mkcd new-project       # mkdir -p new-project && cd new-project
mkcd path/to/deep/dir  # Creates all intermediate directories
```

## Git Functions

### `zsh_git_cleanup` / `git-cleanup`

Clean up merged branches.

```bash
git-cleanup            # Remove local branches merged to main/master
```

**Safety features:**
- Never deletes `main`, `master`, or `develop`
- Only removes fully merged branches
- Shows branches before deletion

### `zsh_gitsize` / `gitsize`

Show repository size breakdown.

```bash
gitsize                # Shows .git size, working tree size, total
```

## Docker Functions

### `zsh_docker_stop_all` / `docker-stop-all`

Stop all running containers.

```bash
docker-stop-all        # Stops every running container
```

### `zsh_docker_rmi_dangling` / `docker-rmi-dangling`

Remove dangling (untagged) images.

```bash
docker-rmi-dangling    # Removes <none>:<none> images
```

### `zsh_docker_rmv_dangling` / `docker-rmv-dangling`

Remove dangling volumes.

```bash
docker-rmv-dangling    # Removes unused anonymous volumes
```

## Network Functions

### `zsh_show_ports` / `ports`

List all listening ports.

```bash
ports                  # Shows all listening TCP/UDP ports
```

**Output includes:**
- Port number
- Process name
- PID

### `zsh_portcheck` / `portcheck`

Check if a specific port is in use.

```bash
portcheck 3000         # Check if port 3000 is in use
portcheck 8080         # Check if port 8080 is in use
```

### `zsh_publicip` / `publicip`

Get your public IP address.

```bash
publicip               # Shows your external IP (via ipify.org)
```

### `zsh_localip` / `localip`

Get your local network IP.

```bash
localip                # Shows your LAN IP address
```

### `zsh_speedtest` / `speedtest`

Test internet connection speed.

```bash
speedtest              # Download speed test via curl
```

### `zsh_waitport` / `waitport`

Wait for a port to become available.

```bash
waitport 5432          # Wait for PostgreSQL default port
waitport 3000 30       # Wait up to 30 seconds for port 3000
```

**Use cases:**
- Wait for database to start before running migrations
- Wait for service to be ready in CI/CD

## Python Functions

### `zsh_activate_venv` / `activate`

Automatically find and activate a Python virtual environment.

```bash
activate               # Auto-detects venv in current or parent dirs
```

**Search locations (in order):**
1. `.venv/bin/activate`
2. `venv/bin/activate`
3. `.env/bin/activate`
4. `env/bin/activate`
5. Parent directories (up to 5 levels)

## Introspection Functions

### `zsh_alias_browser` / `als`

Interactive alias browser with fzf.

```bash
als                    # Browse all aliases
als git                # Pre-filter to git aliases
```

**Key bindings in browser:**
- `Enter` - Copy alias to command line
- `Ctrl-Y` - Copy alias to clipboard
- `Ctrl-E` - Edit alias definition
- `?` - Toggle preview

## Platform-Specific Functions

### macOS Only

| Function | Alias | Description |
|----------|-------|-------------|
| `zsh_killapp` | `killapp` | Quit application by name |
| `zsh_wifi_name` | `wifi` | Show current Wi-Fi network |
| `zsh_wifi_password` | `wifipass` | Show Wi-Fi password |
| `zsh_macos_check_tools` | `checktools` | Check recommended tools |

```bash
killapp Safari         # Quit Safari gracefully
wifi                   # "MyNetwork"
wifipass               # Password for current network
wifipass "Other Net"   # Password for specific network
checktools             # Shows installed/missing tools
```

### Linux Only

| Function | Alias | Description |
|----------|-------|-------------|
| `zsh_linux_check_tools` | `checktools` | Check recommended tools |

## Dependencies

Most functions work without dependencies, but some require:

| Function | Requires |
|----------|----------|
| `calc` | Python 3 |
| `weather` | curl |
| `pskill` | fzf |
| `extract` | Archive tools (tar, unzip, 7z, etc.) |
| `yazi` | yazi file manager |
| `todos` | ripgrep (rg) |
| `alias_browser` | fzf |
| `speedtest` | curl |
| `publicip` | curl |

## Adding Custom Functions

Create functions in `local.zsh` (gitignored):

```bash
# Custom function example
my_func() {
    echo "Hello from my function"
}

# Or add to lib/functions/ for organization
# (requires restart or source)
```

## Auto-Loading

Functions are loaded via `lib/functions/index.zsh` which auto-discovers all `.zsh` files in the functions directory.
