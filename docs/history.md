# History Module

Advanced history management with security filtering, interactive search, and intelligent deduplication.

## Features

### Security First

- **Automatic Sensitive Command Filtering** - 60+ patterns prevent saving passwords, tokens, API keys, and secrets
- **Secure File Permissions** - History directory (700) and file (600) permissions automatically enforced
- **Space-Prefix Filtering** - Commands starting with a space are never saved (`HIST_IGNORE_SPACE`)

### Interactive Search

Press `h` or `Ctrl-R` for an elegant fzf-powered search experience:

```
┌─────────────────────────────────────────────────────────────┐
│ > docker                                                     │
│   3/156 ─────────────────────────────────────────────────── │
│ > docker-compose up -d                                       │
│   docker build -t myapp .                                    │
│   docker ps -a                                               │
├─────────────────────────────────────────────────────────────┤
│ Command preview:                                             │
│ docker-compose up -d                                         │
└─────────────────────────────────────────────────────────────┘
```

**Key Bindings in Search:**

| Key | Action |
|-----|--------|
| `Enter` | Select and execute command |
| `Ctrl-Y` | Copy command to clipboard |
| `Ctrl-/` | Toggle preview window |
| `Ctrl-L` | Clear search query |
| `Esc` | Cancel |

### History Management

- **Smart Deduplication** - Keeps only the most recent occurrence of each command
- **Visual Statistics** - Bar charts showing your most-used commands
- **Interactive Backup** - Choose backup locations with safety prompts
- **Concurrent Access Protection** - Locking prevents corruption from multiple shells

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `history_search_interactive` | `h` | Interactive fzf search |
| `history` | `hh` | Raw history output |
| `history \| less` | `hl` | Browse with pager |
| `history \| grep` | `hs` | Search with grep |
| `history_backup` | `hbackup` | Interactive backup |
| `history_clean` | `hclean` | Remove duplicates & sensitive commands |
| `history_stats [n]` | `hstats [n]` | Show top N commands (bar chart) |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_HISTORY_ENABLED` | `true` | Enable/disable history module |
| `ZSH_HISTORY_SIZE` | `100000` | Commands kept in memory |
| `ZSH_HISTORY_SAVE_SIZE` | `100000` | Commands saved to file |
| `ZSH_HISTORY_SECURITY_FILTER` | `true` | Filter sensitive commands |

## Protected Patterns

Commands matching these patterns are automatically excluded from history:

### Secrets & Credentials
```
*=*api_key*        *=*password*       *=*secret*
*=*private_key*    *=*credential*     *=*access_token*
```

### Environment Exports
```
export *KEY=*      export *SECRET=*   export *TOKEN=*
export *PASS=*     export *PASSWORD=* export AWS_*
```

### Password Managers
```
op *               bw *               pass *
gopass *           vault *            sops *
keychain *
```

### Cloud Authentication
```
gcloud auth *      az login *         doctl auth *
aws configure *
```

### HTTP Requests with Credentials
```
curl *--user *               curl *-u *:*
curl *--header*Authorization* wget *--password*
```

### Git with Embedded Credentials
```
git clone *://*:*@*    git push *://*:*@*
gh auth login*
```

### Docker & Secrets Files
```
docker login *         docker secret *
*secrets.yaml*         *secrets.env*
*.credentials*
```

## File Locations

| Purpose | Path |
|---------|------|
| History file | `$ZSH_STATE_HOME/history/plain` |
| Backups | `$ZSH_DATA_HOME/backups/history/` |

## Shell Options

The module configures these ZSH options:

| Option | Effect |
|--------|--------|
| `APPEND_HISTORY` | Append to file instead of overwriting |
| `SHARE_HISTORY` | Share between terminal sessions |
| `HIST_IGNORE_ALL_DUPS` | No duplicate commands |
| `HIST_IGNORE_SPACE` | Commands starting with space are private |
| `HIST_REDUCE_BLANKS` | Remove extra whitespace |
| `EXTENDED_HISTORY` | Save timestamps and duration |
| `HIST_VERIFY` | Show command before running (with `!`) |
| `HIST_FIND_NO_DUPS` | No duplicates when searching |
| `HIST_SAVE_NO_DUPS` | No duplicates in file |

## Examples

```bash
# Interactive search with pre-filter
h docker

# Show top 10 most-used commands
hstats 10

# Clean history (removes duplicates and sensitive commands)
hclean

# Backup before system changes
hbackup

# Prevent a command from being saved (prefix with space)
 export SECRET_KEY=abc123
```

## Dependencies

- **Required:** None (basic functionality works)
- **Recommended:** `fzf` for interactive search

```bash
brew install fzf  # macOS
apt install fzf   # Ubuntu/Debian
```
