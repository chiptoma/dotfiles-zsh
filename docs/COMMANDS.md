# Command Reference

Every user-facing command the framework provides.

> Generated from the help registry — do not edit by hand.
> Regenerate with: `just docs-commands`

## Framework Commands

| Command | Description | Function | Platform | Requires |
|---------|-------------|----------|----------|----------|
| `backup` | Create timestamped backup | `z_backup` | all | - |
| `calc` | Safe calculator | `z_calc` | all | - |
| `copyfile` | Copy file contents to clipboard | `z_copyfile` | all | - |
| `copypath` | Copy current path to clipboard | `z_copypath` | all | - |
| `dotbackup` | Snapshot all managed dotfiles + tool configs | `z_dotfiles_backup` | all | - |
| `dotrestore` | Restore dotfiles from a backup | `z_dotfiles_restore` | all | - |
| `envinfo` | Show editor, pager, and viewer configuration | `z_env_info` | all | - |
| `extract` | Universal archive extractor | `z_extract` | all | - |
| `gitignore` | Generate .gitignore from templates | `z_gitignore` | all | - |
| `h` | Interactive history search | `z_history_search` | all | - |
| `ip` | Show public IP address | `z_publicip` | all | - |
| `localip` | Show local IP address | `z_localip` | all | - |
| `mkcd` | Create directory and cd into it | `z_mkcd` | all | - |
| `portcheck` | Check if a port is in use | `z_portcheck` | all | - |
| `ports` | Show listening ports | `z_show_ports` | all | - |
| `profile` | Show per-stage startup timing | `z_profile` | all | - |
| `pskill` | Kill process by name | `z_pskill` | all | - |
| `sizeof` | Show file/directory size | `z_sizeof` | all | - |
| `sshagent` | Show SSH agent provider, socket, and keys | `z_ssh_agent` | all | - |
| `timeout` | Run command with time limit | `z_timeout` | all | - |
| `todos` | Find TODO/FIXME/HACK comments | `z_todos` | all | - |
| `up` | Navigate up N directories | `z_up` | all | - |
| `waitport` | Wait for remote port to open | `z_waitport` | all | - |
| `weather` | Weather forecast from wttr.in | `z_weather` | all | - |
| `xdg-check` | XDG compliance scan and stray file report | `z_xdg_check` | all | - |
| `xdg-fix` | Interactive XDG migration tool | `z_xdg_fix` | all | - |
| `xdg-status` | One-line XDG compliance status | `z_xdg_status` | all | - |
| `zhistbackup` | Backup history file | `z_history_backup` | all | - |
| `zhistclean` | Clean history file | `z_history_clean` | all | - |
| `zhistsearch` | Interactive history search (fzf) | `z_history_search` | all | fzf |
| `zhiststats` | History statistics | `z_history_stats` | all | - |

## Tool Commands (require the named tool)

| Command | Description | Function | Platform | Requires |
|---------|-------------|----------|----------|----------|
| `activate` | Activate nearest virtualenv | `z_activate_venv` | all | python |
| `als` | Interactive alias browser | `z_alias_browser` | all | fzf |
| `drmi` | Remove dangling images | `z_docker_cleanup` | all | docker |
| `drmv` | Remove dangling volumes | `z_docker_cleanup` | all | docker |
| `dstop` | Stop all running containers | `z_docker_cleanup` | all | docker |
| `gcleanup` | Delete merged branches safely | `z_git_cleanup` | all | git |
| `gitsize` | Show git repository size | `z_gitsize` | all | git |
| `killapp` | Quit macOS app gracefully | `z_killapp` | macos | osascript |
| `speedtest` | Run internet speed test | `z_speedtest` | all | speedtest-cli |
| `wifi-name` | Current WiFi network name | `z_wifi_name` | macos | macOS |
| `wifi-pass` | WiFi password from Keychain | `z_wifi_password` | macos | macOS |
| `y` | Yazi file manager (cd on exit) | `z_yazi` | all | yazi |

## Discovery & Introspection

| Command | Description | Function | Platform | Requires |
|---------|-------------|----------|----------|----------|
| `check-tools` | Check recommended CLI tools | `z_check_tools` | all | - |
| `compclean` | Remove stale compiled .zwc files | `z_cleanup_zwc` | all | - |
| `help` | This help system | `z_help` | all | - |
| `lazy` | Lazy loading status | `z_lazy_status` | all | - |
| `zbench` | Benchmark shell startup time | `z_benchmark` | all | - |
| `zenv` | Show environment settings | `z_env_show` | all | - |
| `zenvreload` | Reload environment module | `z_env_reload` | all | - |
| `zenvstatus` | Environment detection status | `z_env_status` | all | - |
| `zhealth` | Diagnostic health check | `z_health` | all | - |
| `zpath` | Show all PATH entries | `z_path_show` | all | - |
| `zpathclean` | Clean non-existent PATH entries | `_path_clean` | all | - |
| `zpathcontains` | Check if directory is in PATH | `z_path_contains` | all | - |
| `zpathdebug` | PATH debug information | `z_path_debug` | all | - |
| `zpathinvalid` | Check for non-existent PATH entries | `z_path_invalid` | all | - |
| `zpathreload` | Reload path module | `z_path_reload` | all | - |
| `zpathwhich` | Find which PATH provides a command | `z_path_which` | all | - |
| `zstatus` | Module and tool status | `z_status` | all | - |
| `zupdate` | Update to latest version | `z_update` | all | - |
| `zversion` | Show framework version | `z_version` | all | - |
