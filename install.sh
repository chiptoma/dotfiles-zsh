#!/usr/bin/env bash
# ==============================================================================
# ZSH DOTFILES INSTALLER
# Interactive installer for the ZSH configuration framework.
# Supports macOS and Linux with full cross-platform compatibility.
# ==============================================================================

set -euo pipefail

# ----------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------

# Handle curl-pipe execution (BASH_SOURCE is empty when piped)
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    # Running via: curl ... | bash
    # We need to clone the repo first
    SCRIPT_DIR=""
    CURL_PIPE_MODE=true
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CURL_PIPE_MODE=false
fi
VERSION="2.0.0"

# These are initialized in init_paths() to ensure HOME is correct
INSTALL_DIR=""
DATA_DIR=""
CACHE_DIR=""
STATE_DIR=""
BACKUP_DIR=""

# Non-interactive mode (set via --yes flag)
AUTO_YES=false

# Backup directory chosen via --restore (empty = newest ~/.zsh-backup-*)
RESTORE_DIR=""

# Default-shell handling: "" = ask (interactive) / skip (unattended),
# "yes" = --default-shell, "no" = --no-default-shell
SET_DEFAULT_SHELL=""

# Dry-run mode (set via --dry-run flag)
DRY_RUN=false

# Quiet mode (set via --quiet flag)
QUIET=false

# Skip optional tools (set via --skip-tools flag)
SKIP_TOOLS=false

# Verbose mode (set via --verbose flag) - shows debug output
VERBOSE=false

# Installation profile: minimal, recommended (default), full
INSTALL_PROFILE="recommended"

# True when --minimal/--full was passed (skips the interactive tool menu)
PROFILE_EXPLICIT=false

# Installation method: symlink, copy, or empty (prompt; copy when unattended)
INSTALL_METHOD=""

# Specific tools to install (set via --tools flag, comma-separated)
SELECTED_TOOLS=""

# Step tracking for progress display
CURRENT_STEP=0
TOTAL_STEPS=7

# Rollback tracking
ROLLBACK_ACTIONS=()

# Installation warnings (for partial success reporting)
INSTALL_WARNINGS=()

# Essential files that must exist for a valid installation
# Used by install_config(), verify_installation(), and repair_installation()
ESSENTIAL_FILES=(
    ".zshenv"
    ".zshrc"
    "lib/core/index.zsh"
    "lib/core/logging.zsh"
    "lib/registry/tools.dat"
    "modules/01_path.zsh"
    "modules/02_environment.zsh"
    "modules/06_aliases.zsh"
)

# Initialize paths (call this at start of main to pick up env overrides)
init_paths() {
    INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
    STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
    BACKUP_DIR="$HOME/.zsh-backup-$(date +%Y%m%d_%H%M%S)"
}

# ----------------------------------------------------------
# COLORS (NO_COLOR support)
# Respects NO_COLOR environment variable per https://no-color.org
# ----------------------------------------------------------

init_colors() {
    # Support NO_COLOR standard (https://no-color.org) and FORCE_COLOR
    if [[ "${FORCE_COLOR:-}" == "1" ]]; then
        # Force colors even if not a TTY
        :
    elif [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        WHITE=''
        NC=''
        BOLD=''
        DIM=''
        return
    fi

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
    BOLD='\033[1m'
    DIM='\033[2m'
}

# Initialize colors immediately
init_colors

# ----------------------------------------------------------
# ASCII LOGO
# ----------------------------------------------------------

print_logo() {
    $QUIET && return
    echo ""
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ______ _____ _   _
   |___  // ____| | | |
      / /| (___ | |_| |
     / /  \___ \|  _  |
    / /__ ____) | | | |
   /_____|_____/|_| |_|  dotfiles

         by ChipToma
EOF
    echo -e "${NC}"
    echo -e "  ${DIM}Modern • Modular • Secure${NC}"
    echo -e "  ${DIM}Version $VERSION${NC}"
    echo ""
}

# ----------------------------------------------------------
# STATUS LINE
# Single updating line to show current operation
# ----------------------------------------------------------

LAST_STATUS_MSG=""

# Update status line (replaces previous line)
# Usage: status "Installing package X..."
status() {
    local msg="$1"
    LAST_STATUS_MSG="$msg"

    # In quiet mode or non-TTY, just print
    if $QUIET || [[ ! -t 1 ]]; then
        return
    fi

    # Clear line and print new status
    printf "\r\033[K  ${DIM}→ %s${NC}" "$msg"
}

# Clear status line
status_clear() {
    if [[ -t 1 ]] && ! $QUIET; then
        printf "\r\033[K"
    fi
    LAST_STATUS_MSG=""
}

# ----------------------------------------------------------
# LIVE OUTPUT STREAMING
# Runs command and shows last line of output in real-time
# ----------------------------------------------------------

# Run a command and display its last output line in real-time
# Usage: run_with_status "Installing ZSH" apt-get install -y zsh
run_with_status() {
    local label="$1"
    shift

    # In non-TTY mode, just run the command silently
    if [[ ! -t 1 ]] || $QUIET; then
        "$@" >/dev/null 2>&1
        return $?
    fi

    local exit_code=0
    local last_line=""

    # Run command and capture output line by line
    {
        "$@" 2>&1
    } | while IFS= read -r line; do
        # Truncate line if too long (keep last 60 chars)
        if [[ ${#line} -gt 60 ]]; then
            last_line="...${line: -57}"
        else
            last_line="$line"
        fi
        # Update status with current line
        printf "\r\033[K  ${DIM}%s: %s${NC}" "$label" "$last_line"
    done

    exit_code=${PIPESTATUS[0]}

    # Clear status line when done
    printf "\r\033[K"

    return $exit_code
}

# ----------------------------------------------------------
# SPINNER FUNCTIONS
# Provides visual feedback for long-running operations
# ----------------------------------------------------------

SPINNER_PID=""
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Start a spinner with a message
# Usage: start_spinner "Installing packages..."
start_spinner() {
    local msg="$1"

    # Skip spinner in quiet mode, non-interactive, or NO_COLOR
    if $QUIET || [[ ! -t 1 ]] || [[ -n "${NO_COLOR:-}" ]]; then
        echo -e "  ${CYAN}→${NC} $msg"
        return
    fi

    # Kill any existing spinner
    stop_spinner

    (
        local i=0
        local len=${#SPINNER_CHARS}
        while true; do
            printf "\r  ${CYAN}%s${NC} %s" "${SPINNER_CHARS:i++%len:1}" "$msg"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
    disown $SPINNER_PID 2>/dev/null || true
}

# Stop the spinner and show result
# Usage: stop_spinner [success|error|warning] "Result message"
stop_spinner() {
    if [[ -n "${SPINNER_PID:-}" ]]; then
        kill $SPINNER_PID 2>/dev/null || true
        wait $SPINNER_PID 2>/dev/null || true
        SPINNER_PID=""
        printf "\r\033[K"  # Clear line
    fi
}

# Complete spinner with status
# Usage: complete_spinner success "Installed successfully"
complete_spinner() {
    local status="$1"
    local msg="$2"

    stop_spinner

    case "$status" in
        success) print_success "$msg" ;;
        error)   print_error "$msg" ;;
        warning) print_warning "$msg" ;;
        *)       print_info "$msg" ;;
    esac
}

# ----------------------------------------------------------
# ROLLBACK SYSTEM
# Tracks changes for recovery on failure
# ----------------------------------------------------------

# Register an action that can be rolled back
# Usage: register_rollback "rm -rf /path/to/dir"
register_rollback() {
    ROLLBACK_ACTIONS+=("$1")
}

# Perform rollback on error
perform_rollback() {
    if [[ ${#ROLLBACK_ACTIONS[@]} -eq 0 ]]; then
        print_dim "No rollback actions registered"
        return
    fi

    echo ""
    print_error "Installation failed! Rolling back changes..."

    # Execute rollback actions in reverse order
    local i
    for (( i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i-- )); do
        local action="${ROLLBACK_ACTIONS[$i]}"
        print_dim "  Rollback: $action"
        eval "$action" 2>/dev/null || true
    done

    print_info "Rollback complete. System restored to previous state."
}

# Restore files from backup directory
# Usage: restore_backup "/path/to/backup"
restore_backup() {
    local backup_dir="$1"
    if [[ ! -d "$backup_dir" ]]; then
        print_dim "No backup directory to restore from"
        return
    fi

    print_info "Restoring from backup: $backup_dir"

    # MANIFEST-driven restore (backups made by this installer version)
    if [[ -f "$backup_dir/MANIFEST" ]]; then
        local orig rel
        while IFS=$'\t' read -r orig rel; do
            [[ -n "$orig" && -e "$backup_dir/$rel" ]] || continue
            mkdir -p "$(dirname "$orig")"
            if [[ -d "$backup_dir/$rel" ]]; then
                rm -rf "$orig"
                cp -r "$backup_dir/$rel" "$orig"
            else
                cp "$backup_dir/$rel" "$orig"
            fi
            print_dim "  Restored $orig"
        done < "$backup_dir/MANIFEST"
        print_success "Backup restored"
        return
    fi

    # Legacy backups without a MANIFEST
    [[ -f "$backup_dir/.zshrc" ]] && cp "$backup_dir/.zshrc" "$HOME/.zshrc" && print_dim "  Restored ~/.zshrc"
    [[ -f "$backup_dir/.zshenv" ]] && cp "$backup_dir/.zshenv" "$HOME/.zshenv" && print_dim "  Restored ~/.zshenv"
    [[ -f "$backup_dir/.zprofile" ]] && cp "$backup_dir/.zprofile" "$HOME/.zprofile" && print_dim "  Restored ~/.zprofile"
    print_success "Backup restored"
}

# ERR trap handler
on_error() {
    local exit_code=$?
    local line_no=$1

    echo ""
    print_error "Installation failed on line $line_no (exit code: $exit_code)"
    echo ""
    echo "  ${YELLOW}${BOLD}Troubleshooting:${NC}"
    echo ""
    echo "  1. ${WHITE}Check permissions:${NC}"
    echo "     - Ensure write access to $HOME"
    echo "     - Check if config directory is writable"
    echo ""
    echo "  2. ${WHITE}Network issues:${NC}"
    echo "     - Verify internet connectivity"
    echo "     - Try: curl -I https://github.com"
    echo ""
    echo "  3. ${WHITE}Try repair mode:${NC}"
    echo "     ./install.sh --repair"
    echo ""
    echo "  4. ${WHITE}Clean install:${NC}"
    echo "     ./install.sh --uninstall"
    echo "     ./install.sh"
    echo ""
    echo "  5. ${WHITE}Get help:${NC}"
    echo "     https://github.com/chiptoma/dotfiles-zsh/issues"
    echo ""

    perform_rollback
    exit $exit_code
}

# Set up ERR trap
trap 'on_error $LINENO' ERR

# ----------------------------------------------------------
# PROGRESS TRACKING
# Shows step-by-step progress through installation
# ----------------------------------------------------------

# Advance to next step and show progress
# Usage: next_step "Step description"
next_step() {
    local description="$1"
    ((CURRENT_STEP++)) || true

    $QUIET && return

    echo ""
    echo -e "${BLUE}${BOLD}[$CURRENT_STEP/$TOTAL_STEPS]${NC} ${BOLD}$description${NC}"
    echo ""
}

# ----------------------------------------------------------
# HELPER FUNCTIONS
# ----------------------------------------------------------

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}${BOLD}── $1 ──${NC}"
    echo ""
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}→${NC} $1"
}

print_dim() {
    echo -e "  ${DIM}$1${NC}"
}

# Print debug message (only when --verbose is used)
print_debug() {
    $VERBOSE && echo -e "  ${DIM}[DEBUG]${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"

    # Auto-yes mode: return true for default=y, false for default=n
    if $AUTO_YES; then
        [[ "$default" == "y" ]]
        return
    fi

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi

    echo -ne "  ${YELLOW}?${NC} $prompt"

    # Try to read from /dev/tty (works even when stdin is piped)
    # Fall back to stdin (only if terminal), then default if all reads fail
    # Note: Use { } 2>/dev/null to suppress redirect errors when /dev/tty doesn't exist
    local response=""
    if { read -r response </dev/tty; } 2>/dev/null; then
        : # Successfully read from /dev/tty
    elif [[ -t 0 ]] && read -r response 2>/dev/null; then
        : # Successfully read from stdin (only if stdin is a terminal)
    else
        response="$default"  # All reads failed or non-interactive, use default
    fi

    if [[ -z "$response" ]]; then
        response="$default"
    fi

    [[ "$response" =~ ^[Yy]$ ]]
}

prompt_choice() {
    local prompt="$1"
    shift
    local -a options=("$@")

    # Auto-yes mode: return first option
    if $AUTO_YES; then
        echo "1"
        return
    fi

    # Output prompts to stderr so they display even when called in $()
    echo -e "  ${YELLOW}?${NC} $prompt" >&2
    local i=1
    for opt in "${options[@]}"; do
        echo -e "    ${CYAN}$i)${NC} $opt" >&2
        ((i++))
    done
    echo -ne "  ${YELLOW}?${NC} Enter choice [1-${#options[@]}]: " >&2

    # Try to read from /dev/tty (works even when stdin is piped)
    # Fall back to stdin (only if terminal), then default (1) if all reads fail
    # Note: Use { } 2>/dev/null to suppress redirect errors when /dev/tty doesn't exist
    local choice=""
    if { read -r choice </dev/tty; } 2>/dev/null; then
        : # Successfully read from /dev/tty
    elif [[ -t 0 ]] && read -r choice 2>/dev/null; then
        : # Successfully read from stdin (only if stdin is a terminal)
    else
        choice="1"  # All reads failed or non-interactive, use first option
    fi

    echo "${choice:-1}"
}

has_cmd() {
    command -v "$1" &>/dev/null
}

# Run command with sudo if not already root
maybe_sudo() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif has_cmd sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

is_wsl() {
    # Detect Windows Subsystem for Linux
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
        return 0
    fi
    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        return 0
    fi
    return 1
}

is_container() {
    # Detect if running in a container (Docker, Podman, etc.)
    [[ -f /.dockerenv ]] || \
    [[ -f /run/.containerenv ]] || \
    grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2>/dev/null
}

# ----------------------------------------------------------
# NETWORK HELPERS
# Retry logic and connectivity checks for reliable downloads
# ----------------------------------------------------------

# Check if network is available
# Returns: 0 if online, 1 if offline
check_network() {
    local timeout=5
    local test_hosts=("github.com" "1.1.1.1" "8.8.8.8")

    for host in "${test_hosts[@]}"; do
        if has_cmd curl; then
            curl -sf --max-time "$timeout" "https://$host" >/dev/null 2>&1 && return 0
        elif has_cmd wget; then
            wget -q --timeout="$timeout" --spider "https://$host" 2>/dev/null && return 0
        elif has_cmd ping; then
            ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1 && return 0
        fi
    done
    return 1
}

# Fetch URL with retry logic
# Usage: fetch_with_retry <url> [output_file]
# If output_file is omitted, outputs to stdout
# Returns: 0 on success, 1 on failure after all retries
fetch_with_retry() {
    local url="$1"
    local output="${2:-}"
    local max_retries=3
    local retry_delay=2
    local timeout=30
    local attempt=1

    print_debug "Fetching: $url"

    while (( attempt <= max_retries )); do
        if [[ -n "$output" ]]; then
            # Download to file
            if has_cmd curl; then
                curl -fsSL --max-time "$timeout" -o "$output" "$url" 2>/dev/null && return 0
            elif has_cmd wget; then
                wget -q --timeout="$timeout" -O "$output" "$url" 2>/dev/null && return 0
            fi
        else
            # Output to stdout
            if has_cmd curl; then
                curl -fsSL --max-time "$timeout" "$url" 2>/dev/null && return 0
            elif has_cmd wget; then
                wget -qO- --timeout="$timeout" "$url" 2>/dev/null && return 0
            fi
        fi

        if (( attempt < max_retries )); then
            print_dim "Network request failed, retrying in ${retry_delay}s... (attempt $attempt/$max_retries)"
            sleep "$retry_delay"
            ((retry_delay *= 2))  # Exponential backoff
        fi
        ((attempt++))
    done

    print_error "Failed to fetch $url after $max_retries attempts"
    return 1
}

get_package_manager() {
    # Check for Nix first (can be installed on any OS)
    if has_cmd nix-env; then
        echo "nix"
        return
    fi

    if is_macos; then
        if has_cmd brew; then
            echo "brew"
        else
            echo "none"
        fi
    elif is_linux; then
        if has_cmd apt; then echo "apt"
        elif has_cmd dnf; then echo "dnf"
        elif has_cmd yum; then echo "yum"
        elif has_cmd pacman; then echo "pacman"
        elif has_cmd apk; then echo "apk"
        elif has_cmd zypper; then echo "zypper"
        else echo "none"
        fi
    else
        echo "none"
    fi
}

# Install a package with live output (handles different package managers)
install_package() {
    local pkg="$1" pm="$2"
    case "$pm" in
        brew)   run_with_status "Installing $pkg" brew install "$pkg" ;;
        nix)    run_with_status "Installing $pkg" nix-env -iA "nixpkgs.$pkg" ;;
        apt)    run_with_status "Updating packages" maybe_sudo apt-get update || true
                run_with_status "Installing $pkg" maybe_sudo apt-get install -y "$pkg" ;;
        dnf)    run_with_status "Installing $pkg" maybe_sudo dnf install -y "$pkg" ;;
        yum)    run_with_status "Installing $pkg" maybe_sudo yum install -y "$pkg" ;;
        pacman) run_with_status "Installing $pkg" maybe_sudo pacman -S --noconfirm --needed "$pkg" ;;
        apk)    run_with_status "Installing $pkg" maybe_sudo apk add "$pkg" ;;
        zypper) run_with_status "Installing $pkg" maybe_sudo zypper install -y "$pkg" ;;
        *)      print_error "Unknown package manager: $pm"; return 1 ;;
    esac
}

# Install a package silently (no status output, for batch operations)
install_package_quiet() {
    local pkg="$1" pm="$2"
    case "$pm" in
        brew)   brew install "$pkg" >/dev/null 2>&1 ;;
        nix)    nix-env -iA "nixpkgs.$pkg" >/dev/null 2>&1 ;;
        apt)    maybe_sudo apt-get install -qq -y "$pkg" >/dev/null 2>&1 ;;
        dnf)    maybe_sudo dnf install -y -q "$pkg" >/dev/null 2>&1 ;;
        yum)    maybe_sudo yum install -y -q "$pkg" >/dev/null 2>&1 ;;
        pacman) maybe_sudo pacman -S --noconfirm --needed -q "$pkg" >/dev/null 2>&1 ;;
        apk)    maybe_sudo apk add -q "$pkg" >/dev/null 2>&1 ;;
        zypper) maybe_sudo zypper install -y -q "$pkg" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

# Ensure unzip is available (required for some tool installations)
ensure_unzip() {
    has_cmd unzip && return 0

    print_dim "Installing unzip (required)..."
    local pm
    pm=$(get_package_manager)
    install_package_quiet "unzip" "$pm"

    if has_cmd unzip; then
        return 0
    else
        print_warning "Could not install unzip"
        return 1
    fi
}

# Get the correct package name for a tool (some have different names per package manager)
get_package_name() {
    local tool="$1" pm="$2"
    case "$tool" in
        fd)       case "$pm" in apt|dnf|yum|zypper) echo "fd-find";; *) echo "fd";; esac ;;
        ripgrep)  echo "ripgrep" ;;
        bat)      echo "bat" ;;
        fzf)      [[ "$pm" == "apt" ]] && echo "SCRIPT:fzf" || echo "fzf" ;;
        eza)      [[ "$pm" == "apt" ]] && echo "SCRIPT:eza" || echo "eza" ;;
        yazi)     case "$pm" in brew|pacman|nix) echo "yazi";; *) echo "SCRIPT:yazi";; esac ;;
        atuin)    case "$pm" in brew|pacman|nix) echo "atuin";; *) echo "SCRIPT:atuin";; esac ;;
        starship) case "$pm" in brew|pacman|dnf|nix) echo "starship";; *) echo "SCRIPT:starship";; esac ;;
        zoxide)   case "$pm" in brew|pacman|dnf|apt|nix) echo "zoxide";; *) echo "CARGO:zoxide";; esac ;;
        *)        echo "$tool" ;;
    esac
}

# Install a tool using alternative methods when not in package manager
install_special_tool() {
    local tool="$1"

    case "$tool" in
        CARGO:*)
            local pkg="${tool#CARGO:}"
            if has_cmd cargo; then
                print_info "Installing $pkg via cargo..."
                cargo install "$pkg"
                return $?
            else
                print_warning "cargo not found, skipping $pkg"
                print_dim "Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
                return 1
            fi
            ;;
        SCRIPT:atuin)
            print_info "Installing atuin..."
            # Atuin installer accepts -y for non-interactive, suppress verbose output
            if has_cmd curl; then
                bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) -y >/dev/null 2>&1
            elif has_cmd wget; then
                bash <(wget -qO- https://setup.atuin.sh) -y >/dev/null 2>&1
            else
                print_error "Neither curl nor wget available"
                return 1
            fi
            # Verify atuin was installed
            if [[ -x "$HOME/.atuin/bin/atuin" ]]; then
                print_success "atuin installed"
            else
                print_warning "atuin installation may have failed"
            fi
            ;;
        SCRIPT:starship)
            print_info "Installing starship..."
            # Suppress verbose starship installer output
            if has_cmd curl; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1
            else
                print_error "curl not available for starship install"
                return 1
            fi
            # Verify starship was installed
            if has_cmd starship; then
                print_success "starship installed"
            else
                print_warning "starship installation may have failed"
            fi
            ;;
        SCRIPT:eza)
            print_info "Installing eza..."
            install_github_binary "eza" \
                'https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-${os}-gnu.tar.gz' \
                "tar"
            ;;
        SCRIPT:fzf)
            print_info "Installing fzf..."
            install_github_binary "fzf" \
                'https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${os}_${arch}.tar.gz' \
                "tar"
            ;;
        SCRIPT:yazi)
            ensure_unzip || { print_warning "Skipping yazi (unzip required)"; return 1; }
            print_info "Installing yazi..."
            install_github_binary "yazi" \
                'https://github.com/sxyazi/yazi/releases/latest/download/yazi-${arch}-unknown-${os}-musl.zip' \
                "unzip"
            ;;
        SCRIPT:*)
            # Generic fallback: most SCRIPT-marked tools are Rust crates whose
            # crate name matches the brew package (btm→bottom, tldr→tealdeer)
            local t="${tool#SCRIPT:}"
            local idx crate
            idx=$(find_catalog_index "$t")
            crate="$t"
            if [[ "$idx" -ge 0 && -n "${CAT_BREWS[$idx]}" && "${CAT_BREWS[$idx]}" != "SCRIPT" ]]; then
                crate="${CAT_BREWS[$idx]}"
            fi
            if has_cmd cargo; then
                print_info "Installing $t via cargo ($crate)..."
                cargo install "$crate" && return 0
            fi
            print_warning "No install recipe for $t on this system — install it manually"
            return 1
            ;;
        *)
            print_error "Unknown special install: $tool"
            return 1
            ;;
    esac
}

# ----------------------------------------------------------
# GENERIC GITHUB BINARY INSTALLER
# Consolidates eza/fzf/yazi installation into one function
# ----------------------------------------------------------

install_github_binary() {
    local tool="$1" url_pattern="$2" extract_cmd="$3" bin_name="${4:-$1}"

    local arch=$(uname -m) os=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Normalize architecture per tool (each has different naming conventions)
    case "$tool:$arch" in
        fzf:x86_64)           arch="amd64" ;;
        fzf:aarch64|fzf:arm64) arch="arm64" ;;
        eza:arm64)            arch="aarch64" ;;
        yazi:arm64)           arch="aarch64" ;;
        *:aarch64)            arch="aarch64" ;;
        *:arm64)              arch="aarch64" ;;
    esac

    # Check for unsupported architectures
    case "$arch" in
        x86_64|amd64|aarch64|arm64) ;;
        *) print_warning "Unsupported architecture for $tool: $arch"; return 1 ;;
    esac

    # Build URL from pattern (uses eval to expand $arch, $os, $version)
    local version url
    if [[ "$url_pattern" == *'${version}'* ]]; then
        # Fetch latest version for tools that need it (fzf)
        version=$(curl -fsSL "https://api.github.com/repos/junegunn/fzf/releases/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 | sed 's/.*"v\?\([^"]*\)".*/\1/')
        [[ -z "$version" ]] && version="0.56.3"  # Fallback
    fi
    url=$(eval echo "$url_pattern")

    local tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" RETURN

    # Download with retries (GitHub can rate limit)
    local retry_count=0 max_retries=3
    while (( retry_count < max_retries )); do
        if curl -fsSL --retry 2 --retry-delay 1 "$url" -o "$tmp_dir/archive" 2>/dev/null; then
            break
        fi
        (( retry_count++ ))
        [[ $retry_count -lt $max_retries ]] && sleep 2
    done

    if [[ ! -s "$tmp_dir/archive" ]]; then
        print_warning "Failed to download $tool (after $max_retries attempts)"
        return 1
    fi

    # Extract based on type
    case "$extract_cmd" in
        tar)   tar -xzf "$tmp_dir/archive" -C "$tmp_dir" 2>/dev/null ;;
        unzip) unzip -q "$tmp_dir/archive" -d "$tmp_dir" 2>/dev/null ;;
        pipe)  tar -xz -C "$tmp_dir" < "$tmp_dir/archive" 2>/dev/null ;;
    esac

    # Find binary (may be in subdirectory)
    local binary=$(find "$tmp_dir" -name "$bin_name" -type f 2>/dev/null | head -1)
    [[ -z "$binary" ]] && binary="$tmp_dir/$bin_name"

    # Determine install location
    local install_dir="/usr/local/bin"
    if [[ ! -w "$install_dir" ]] && [[ $EUID -ne 0 ]]; then
        install_dir="$HOME/.local/bin"
        mkdir -p "$install_dir"
    fi

    # Install binary
    if [[ -f "$binary" ]]; then
        chmod +x "$binary"
        maybe_sudo install -m 755 "$binary" "$install_dir/$bin_name" 2>/dev/null
        if has_cmd "$bin_name" || [[ -x "$install_dir/$bin_name" ]]; then
            print_success "$tool installed"
            return 0
        fi
    fi

    print_warning "Failed to install $tool from GitHub"
    return 1
}


# ----------------------------------------------------------
# PRE-FLIGHT CHECKS
# Verify system requirements before installation
# ----------------------------------------------------------

preflight_checks() {
    local all_good=true

    # Check write permissions to config directory parent
    local config_parent
    config_parent=$(dirname "$INSTALL_DIR")
    if [[ ! -d "$config_parent" ]]; then
        if ! mkdir -p "$config_parent" 2>/dev/null; then
            print_error "Cannot create directory: $config_parent"
            print_info "Check permissions on $(dirname "$config_parent")"
            all_good=false
        else
            print_success "Can create config directory"
            rmdir "$config_parent" 2>/dev/null || true
        fi
    elif [[ ! -w "$config_parent" ]]; then
        print_error "No write permission to $config_parent"
        all_good=false
    else
        print_success "Write access to $config_parent"
    fi

    # Check write permissions to HOME
    if [[ ! -w "$HOME" ]]; then
        print_error "No write permission to HOME ($HOME)"
        all_good=false
    else
        print_success "Write access to HOME"
    fi

    # Check available disk space (need at least 10MB)
    local available_kb
    if is_macos; then
        available_kb=$(df -k "$HOME" | awk 'NR==2 {print $4}')
    else
        available_kb=$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
    fi

    if [[ -n "$available_kb" ]] && [[ "$available_kb" -lt 10240 ]]; then
        print_error "Insufficient disk space (need 10MB, have $((available_kb/1024))MB)"
        all_good=false
    elif [[ -n "$available_kb" ]]; then
        print_success "Sufficient disk space ($((available_kb/1024))MB available)"
    else
        print_warning "Could not check disk space"
    fi

    # Check if running as root (discouraged)
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root is not recommended"
        print_info "The configuration will be installed for the root user"
    fi

    # Check network connectivity (required for plugins and tools)
    status "Checking network connectivity..."
    if check_network; then
        status_clear
        print_success "Network connection available"
    else
        status_clear
        print_error "No network connection"
        print_info "Network is required to install plugins and CLI tools."
        print_info "Please check your internet connection and try again."
        return 1
    fi

    if ! $all_good; then
        echo ""
        print_error "Pre-flight checks failed. Please resolve the issues above."
        return 1
    fi

    return 0
}

# ----------------------------------------------------------
# ZSH INSTALLATION
# Offers to install ZSH if not present
# ----------------------------------------------------------

offer_zsh_install() {
    local pm
    pm=$(get_package_manager)

    if [[ "$pm" == "none" ]]; then
        print_error "No package manager available to install ZSH"
        print_info "Please install ZSH manually:"
        print_dim "  macOS: brew install zsh"
        print_dim "  Ubuntu/Debian: sudo apt install zsh"
        print_dim "  Fedora: sudo dnf install zsh"
        print_dim "  Arch: sudo pacman -S zsh"
        print_dim "  NixOS: nix-env -iA nixpkgs.zsh"
        return 1
    fi

    if ! confirm "Install ZSH using $pm?" "y"; then
        return 1
    fi

    if install_package "zsh" "$pm" && has_cmd zsh; then
        print_success "ZSH installed successfully"
        return 0
    fi

    print_error "Failed to install ZSH"
    return 1
}

# ----------------------------------------------------------
# DEFAULT SHELL SETUP
# Offers to set ZSH as the default shell
# ----------------------------------------------------------

offer_set_default_shell() {
    # Check if ZSH is already default
    local current_shell
    current_shell=$(basename "${SHELL:-}")

    if [[ "$current_shell" == "zsh" ]]; then
        print_success "ZSH is already your default shell"
        return 0
    fi

    print_info "Your current shell is: $current_shell"

    # Explicit opt-out, or unattended without explicit opt-in: chsh can
    # prompt for a password and hang automation (Ansible, CI)
    if [[ "$SET_DEFAULT_SHELL" == "no" ]]; then
        print_dim "Skipping default-shell change (--no-default-shell)"
        return 0
    fi
    if $AUTO_YES && [[ "$SET_DEFAULT_SHELL" != "yes" ]]; then
        print_dim "Unattended mode: not changing the default shell"
        print_dim "Pass --default-shell to opt in, or run: chsh -s $(command -v zsh)"
        return 0
    fi

    if ! confirm "Set ZSH as your default shell?" "y"; then
        print_dim "You can change it later with: chsh -s $(command -v zsh)"
        return 0
    fi

    local zsh_path
    zsh_path=$(command -v zsh)

    # macOS: check if zsh is in /etc/shells
    if is_macos; then
        if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
            print_info "Adding $zsh_path to /etc/shells..."
            echo "$zsh_path" | maybe_sudo tee -a /etc/shells >/dev/null
        fi
    fi

    start_spinner "Setting default shell..."

    # Use chsh (may prompt for password)
    if chsh -s "$zsh_path" 2>/dev/null; then
        complete_spinner success "Default shell set to ZSH"
        print_info "Changes take effect on next login"
    else
        complete_spinner warning "Could not set default shell automatically"
        print_info "Run manually: chsh -s $zsh_path"
    fi
}

# ----------------------------------------------------------
# SYSTEM CHECKS
# ----------------------------------------------------------

check_requirements() {
    local all_good=true
    local pm
    pm=$(get_package_manager)

    # Show platform first
    if is_macos; then
        print_info "Platform: macOS ($(uname -m))"
    elif is_linux; then
        local distro="unknown"
        if [[ -f /etc/os-release ]]; then
            distro=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
        fi
        if is_wsl; then
            print_info "Platform: WSL ($distro)"
            # WSL-specific notes
            echo ""
            echo "  ${DIM}WSL detected. Notes:${NC}"
            echo "  ${DIM}- Windows paths are available via /mnt/c/${NC}"
            echo "  ${DIM}- Some tools may need Windows Terminal for best experience${NC}"
            echo "  ${DIM}- Consider installing a Nerd Font in Windows Terminal${NC}"
            echo ""
        elif is_container; then
            print_info "Platform: Container ($distro)"
        else
            print_info "Platform: Linux ($distro)"
        fi
    else
        print_warning "Platform: Unknown ($(uname -s))"
    fi

    # Check package manager
    if [[ "$pm" != "none" ]]; then
        print_success "Package manager: $pm"
    else
        print_warning "No supported package manager found"
    fi

    # Helper: Check and optionally install a required tool
    require_tool() {
        local tool="$1" reason="$2" alt="${3:-}"
        if has_cmd "$tool"; then
            [[ "$tool" == "git" ]] && print_success "Git installed ($(git --version | awk '{print $3}'))" && return 0
            print_success "$tool installed"
            return 0
        fi
        [[ -n "$alt" ]] && has_cmd "$alt" && { print_success "$alt installed"; return 0; }

        print_error "$tool not found ($reason)"
        [[ "$pm" == "none" ]] && return 1
        if confirm "Install $tool using $pm?" "y"; then
            install_package "$tool" "$pm" && { print_success "$tool installed"; return 0; }
            print_error "Failed to install $tool"
        fi
        return 1
    }

    # Check essential tools (needed for installation)
    require_tool "git" "required for plugin installation" || all_good=false
    require_tool "curl" "required for downloads" "wget" || all_good=false

    # Now check ZSH (after we have git and curl for installation)
    if has_cmd zsh; then
        local zsh_version
        zsh_version=$(zsh --version | awk '{print $2}')
        print_success "ZSH installed (version $zsh_version)"
    else
        print_warning "ZSH not found"
        if offer_zsh_install; then
            print_success "ZSH installed"
        else
            print_error "ZSH is required but not installed"
            all_good=false
        fi
    fi

    if ! $all_good; then
        echo ""
        print_error "Missing required dependencies. Please install them first."
        exit 3
    fi
}

# ----------------------------------------------------------
# ZSH PLUGINS (self-managed — no Oh My Zsh)
# ----------------------------------------------------------

install_plugins() {
    local plugins_dir="$DATA_DIR/zsh/plugins"
    local legacy_dir="$DATA_DIR/oh-my-zsh/custom/plugins"
    mkdir -p "$plugins_dir"

    # Migrate clones from the pre-native OMZ layout instead of re-downloading
    local -a plugin_names=(zsh-autosuggestions zsh-syntax-highlighting fzf-tab)
    local name
    for name in "${plugin_names[@]}"; do
        if [[ -d "$legacy_dir/$name" && ! -d "$plugins_dir/$name" ]]; then
            mv "$legacy_dir/$name" "$plugins_dir/$name"
            print_dim "Migrated $name from the old Oh My Zsh layout"
        fi
    done

    # The three plugins the framework loads (lib/plugins/index.zsh);
    # shell works without them, with reduced UX
    local -a plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
        "fzf-tab:https://github.com/Aloxaf/fzf-tab"
    )
    local custom_dir="$plugins_dir"

    local plugin_count=${#plugins[@]}
    local plugin_current=0
    local failed_plugins=0

    for entry in "${plugins[@]}"; do
        local name="${entry%%:*}"
        local url="${entry#*:}"
        local target="$custom_dir/$name"

        ((plugin_current++)) || true

        if [[ -d "$target" ]]; then
            status "[$plugin_current/$plugin_count] $name (cached)"
            sleep 0.2  # Brief pause so user sees cached status
            continue
        fi

        # Retry up to 3 times with exponential backoff
        local attempt=1
        local max_attempts=3
        local retry_delay=2
        local success=false

        while (( attempt <= max_attempts )) && ! $success; do
            status "[$plugin_current/$plugin_count] $name (attempt $attempt/$max_attempts)..."
            if git clone --depth=1 "$url" "$target" 2>/dev/null; then
                success=true
            else
                rm -rf "$target" 2>/dev/null  # Clean up failed clone
                if (( attempt < max_attempts )); then
                    sleep "$retry_delay"
                    ((retry_delay *= 2))
                fi
                ((attempt++))
            fi
        done

        status_clear
        if $success; then
            print_success "$name installed"
        else
            print_warning "Failed to install $name after $max_attempts attempts"
            ((failed_plugins++))
        fi
    done

    status_clear

    if (( failed_plugins > 0 )); then
        echo ""
        print_warning "$failed_plugins plugin(s) failed to install"
        print_info "Shell will work but with reduced functionality:"
        print_dim "  - zsh-autosuggestions: command suggestions as you type"
        print_dim "  - zsh-syntax-highlighting: command syntax coloring"
        print_dim "  - fzf-tab: fuzzy completion menu"
        echo ""
        # Track for final summary
        INSTALL_WARNINGS+=("$failed_plugins zsh plugin(s) failed to install")
    else
        print_success "Plugins installed ($plugin_count plugins)"
    fi
}

# ----------------------------------------------------------
# BACKUP EXISTING CONFIG
# ----------------------------------------------------------

backup_existing() {
    # Shell entry files + the install dir
    local -a existing_files=()
    [[ -f "$HOME/.zshrc" ]] && existing_files+=("$HOME/.zshrc")
    [[ -f "$HOME/.zshenv" ]] && existing_files+=("$HOME/.zshenv")
    [[ -f "$HOME/.zprofile" ]] && existing_files+=("$HOME/.zprofile")
    [[ -d "$INSTALL_DIR" && "$INSTALL_DIR" != "$SCRIPT_DIR" ]] && existing_files+=("$INSTALL_DIR")

    # Tool configs the installer may overwrite (tools/manifest.dat)
    local manifest="$SCRIPT_DIR/tools/manifest.dat"
    local -a config_dests=()
    if [[ -f "$manifest" ]]; then
        local tool src dest mode dest_path
        while IFS=: read -r tool src dest mode; do
            case "$tool" in "#"*|"") continue ;; esac
            dest_path="${dest//\$XDG_CONFIG_HOME/${XDG_CONFIG_HOME:-$HOME/.config}}"
            dest_path="${dest_path/#\~/$HOME}"
            [[ -f "$dest_path" ]] && config_dests+=("$tool:$dest_path")
        done < "$manifest"
    fi

    if [[ ${#existing_files[@]} -eq 0 && ${#config_dests[@]} -eq 0 ]]; then
        print_success "No existing configuration to backup"
        return 0
    fi

    echo "  Found existing files:"
    local file entry
    for file in "${existing_files[@]}"; do
        print_dim "  - $file"
    done
    for entry in "${config_dests[@]}"; do
        print_dim "  - ${entry#*:} (${entry%%:*} config)"
    done
    echo ""

    if confirm "Backup existing configuration?" "y"; then
        mkdir -p "$BACKUP_DIR"
        # MANIFEST maps original path -> backup-relative path (tab-separated)
        : > "$BACKUP_DIR/MANIFEST"

        for file in "${existing_files[@]}"; do
            if [[ -e "$file" ]]; then
                local base
                base=$(basename "$file")
                cp -r "$file" "$BACKUP_DIR/$base"
                printf '%s\t%s\n' "$file" "$base" >> "$BACKUP_DIR/MANIFEST"
                print_success "Backed up: $file"
            fi
        done

        for entry in "${config_dests[@]}"; do
            local tool="${entry%%:*}" path="${entry#*:}" base
            base=$(basename "$path")
            mkdir -p "$BACKUP_DIR/tools/$tool"
            cp "$path" "$BACKUP_DIR/tools/$tool/$base"
            printf '%s\t%s\n' "$path" "tools/$tool/$base" >> "$BACKUP_DIR/MANIFEST"
            print_success "Backed up: $path"
        done

        print_info "Backup location: $BACKUP_DIR"

        # Register rollback action to restore from backup
        register_rollback "restore_backup '$BACKUP_DIR'"
    else
        print_warning "Skipping backup (existing files may be overwritten)"
    fi
}

# Keep the newest 5 backups; always ask before deleting, never unattended
prune_old_backups() {
    $AUTO_YES && return 0
    local -a backups=()
    local d
    while IFS= read -r d; do
        backups+=("$d")
    done < <(ls -dt "$HOME"/.zsh-backup-* 2>/dev/null)
    [[ ${#backups[@]} -le 5 ]] && return 0

    local n_old=$(( ${#backups[@]} - 5 ))
    if confirm "Found ${#backups[@]} zsh backups — delete the $n_old oldest?" "n"; then
        local i
        for ((i = 5; i < ${#backups[@]}; i++)); do
            rm -rf "${backups[$i]}"
            print_dim "  Removed ${backups[$i]}"
        done
    fi
}

# ----------------------------------------------------------
# INSTALLATION
# ----------------------------------------------------------

install_config() {
    # Determine installation method
    local method
    if [[ "$SCRIPT_DIR" == "$INSTALL_DIR" ]]; then
        print_info "Already in target directory, no installation needed"
        method="none"
    elif [[ "$SCRIPT_DIR" == /tmp/* ]]; then
        # Source is in temp directory (curl-pipe mode) - copy files
        if [[ "$INSTALL_METHOD" == "symlink" ]]; then
            print_warning "--symlink unavailable from a temporary checkout, using copy"
        fi
        method="copy"
        print_info "Using copy installation (curl-pipe mode)"
    elif [[ -n "$INSTALL_METHOD" ]]; then
        method="$INSTALL_METHOD"
        print_info "Using $method installation (--$method)"
    elif $AUTO_YES; then
        # Unattended default: copy is self-contained and survives repo moves
        method="copy"
        print_info "Using copy installation (unattended default; pass --symlink to override)"
    else
        local choice
        choice=$(prompt_choice "How would you like to install?" "Symlink (recommended for development)" "Copy files")

        case "$choice" in
            1) method="symlink" ;;
            2) method="copy" ;;
            *) method="symlink" ;;
        esac
    fi

    # Atomic installation: use temp directory, verify, then move
    local temp_install=""

    case "$method" in
        symlink)
            # Validate source has essential files BEFORE symlinking
            for file in "${ESSENTIAL_FILES[@]}"; do
                if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
                    print_error "Essential file missing in source: $file"
                    print_error "Cannot symlink incomplete configuration"
                    print_info "Ensure you have a complete checkout of the repository"
                    return 1
                fi
            done

            print_info "Creating symlink..."
            if $DRY_RUN; then
                print_dim "[dry-run] mkdir -p $(dirname "$INSTALL_DIR")"
                print_dim "[dry-run] rm -rf $INSTALL_DIR"
                print_dim "[dry-run] ln -sf $SCRIPT_DIR $INSTALL_DIR"
            else
                mkdir -p "$(dirname "$INSTALL_DIR")"
                rm -rf "$INSTALL_DIR" 2>/dev/null
                ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
                # Register rollback to remove symlink
                register_rollback "rm -f '$INSTALL_DIR'"
            fi
            print_success "Symlinked $SCRIPT_DIR -> $INSTALL_DIR"
            ;;
        copy)
            print_info "Copying files (atomic)..."
            if $DRY_RUN; then
                print_dim "[dry-run] mkdir -p $INSTALL_DIR.tmp.$$"
                print_dim "[dry-run] cp -r $SCRIPT_DIR/. $INSTALL_DIR.tmp.$$/"
                print_dim "[dry-run] verify essential files"
                print_dim "[dry-run] rm -rf $INSTALL_DIR"
                print_dim "[dry-run] mv $INSTALL_DIR.tmp.$$ $INSTALL_DIR"
            else
                temp_install="$INSTALL_DIR.tmp.$$"

                # Copy to temp location (use /. to include dotfiles)
                mkdir -p "$temp_install"
                if ! cp -r "$SCRIPT_DIR"/. "$temp_install/"; then
                    print_error "Failed to copy files"
                    rm -rf "$temp_install"
                    return 1
                fi

                # Verify essential files exist in temp
                for file in "${ESSENTIAL_FILES[@]}"; do
                    if [[ ! -f "$temp_install/$file" ]]; then
                        print_error "Essential file missing in copy: $file"
                        rm -rf "$temp_install"
                        return 1
                    fi
                done

                # Atomic swap: rename old first, then move new
                # This prevents data loss if interrupted between operations
                local old_backup="${INSTALL_DIR}.old.$$"
                if [[ -d "$INSTALL_DIR" ]]; then
                    mv "$INSTALL_DIR" "$old_backup" 2>/dev/null || true
                fi
                if ! mv "$temp_install" "$INSTALL_DIR"; then
                    print_error "Failed to move files to final location"
                    # Attempt recovery from old backup
                    if [[ -d "$old_backup" ]]; then
                        mv "$old_backup" "$INSTALL_DIR" 2>/dev/null || true
                    elif [[ -d "$temp_install" ]]; then
                        mv "$temp_install" "$INSTALL_DIR" 2>/dev/null || true
                    fi
                    return 1
                fi
                # Preserve user-local config from the replaced install
                if [[ -f "$old_backup/.zshlocal" ]]; then
                    cp "$old_backup/.zshlocal" "$INSTALL_DIR/.zshlocal"
                    print_success "Preserved existing .zshlocal"
                fi

                # Clean up old backup after successful swap
                rm -rf "$old_backup" 2>/dev/null

                # Register rollback to remove copied files
                register_rollback "rm -rf '$INSTALL_DIR'"
            fi
            print_success "Copied to $INSTALL_DIR"
            ;;
        none)
            # Already in place
            ;;
    esac

    # Create XDG directories
    print_info "Creating XDG directories..."
    if $DRY_RUN; then
        print_dim "[dry-run] mkdir -p $DATA_DIR/zsh $CACHE_DIR/zsh $STATE_DIR/zsh"
    else
        mkdir -p "$DATA_DIR/zsh"
        mkdir -p "$CACHE_DIR/zsh"
        mkdir -p "$STATE_DIR/zsh"
    fi
    print_success "XDG directories created"
}

setup_zdotdir() {
    local system_zshenv="$HOME/.zshenv"

    # ZSH doesn't auto-source $ZDOTDIR/.zshenv after ZDOTDIR is set mid-file,
    # so we must explicitly source it to load utils, logging, etc.
    local zshenv_content
    zshenv_content="export ZDOTDIR=\"$INSTALL_DIR\"
[[ -r \"\$ZDOTDIR/.zshenv\" ]] && source \"\$ZDOTDIR/.zshenv\""

    # Check if already configured
    if [[ -f "$system_zshenv" ]] && grep -q "ZDOTDIR" "$system_zshenv" 2>/dev/null; then
        # Extract existing ZDOTDIR value
        local existing_zdotdir
        existing_zdotdir=$(grep -oP 'ZDOTDIR=["'"'"']?\K[^"'"'"']+' "$system_zshenv" 2>/dev/null | head -1)

        # Check if it already points to our install location
        if [[ "$existing_zdotdir" == "$INSTALL_DIR" ]]; then
            print_success "ZDOTDIR already correctly configured"
            return 0
        fi

        print_info "ZDOTDIR already configured in ~/.zshenv"
        print_dim "  Current: $existing_zdotdir"
        print_dim "  New:     $INSTALL_DIR"

        if confirm "Overwrite existing ~/.zshenv?" "y"; then
            if $DRY_RUN; then
                print_dim "[dry-run] Writing ZDOTDIR config to $system_zshenv"
            else
                printf '%s\n' "$zshenv_content" > "$system_zshenv"
                register_rollback "rm -f '$system_zshenv'"
            fi
            print_success "Updated ~/.zshenv"
        else
            # User declined but ZDOTDIR points elsewhere - this will break the shell
            print_error "Cannot continue: ZDOTDIR points to different location"
            print_error "Your shell would load config from: $existing_zdotdir"
            print_error "But we installed to: $INSTALL_DIR"
            print_info "Either overwrite ~/.zshenv or uninstall and reinstall to the existing location"
            return 1
        fi
    else
        if $DRY_RUN; then
            print_dim "[dry-run] Writing ZDOTDIR config to $system_zshenv"
        else
            printf '%s\n' "$zshenv_content" > "$system_zshenv"
            register_rollback "rm -f '$system_zshenv'"
        fi
        print_success "Created ~/.zshenv with ZDOTDIR"
    fi

    return 0
}

# ----------------------------------------------------------
# OPTIONAL TOOLS
# ----------------------------------------------------------

# Tool catalog: parsed from lib/registry/tools.dat — the single source of
# truth shared with the zsh runtime (lib/registry/tools.zsh).
# Parallel indexed arrays: macOS ships bash 3.2, no associative arrays.
CAT_NAMES=()
CAT_BINS=()
CAT_DESCS=()
CAT_CATEGORIES=()
CAT_REPLACES_LIST=()
CAT_BREWS=()
CAT_APTS=()

load_tool_catalog() {
    # Idempotent: parse once
    [[ ${#CAT_NAMES[@]} -gt 0 ]] && return 0

    local catalog="$SCRIPT_DIR/lib/registry/tools.dat"
    if [[ -f "$catalog" ]]; then
        local name binary desc category replaces brew apt
        while IFS=: read -r name binary desc category replaces brew apt; do
            case "$name" in "#"*|"") continue ;; esac
            CAT_NAMES+=("$name")
            CAT_BINS+=("$binary")
            CAT_DESCS+=("$desc")
            CAT_CATEGORIES+=("$category")
            CAT_REPLACES_LIST+=("$replaces")
            CAT_BREWS+=("$brew")
            CAT_APTS+=("$apt")
        done < "$catalog"
    fi

    # Embedded minimal fallback keeps curl-pipe bootstraps working even if
    # the catalog is somehow absent
    if [[ ${#CAT_NAMES[@]} -eq 0 ]]; then
        print_warning "Tool catalog missing ($catalog) — using minimal embedded set"
        CAT_NAMES=(starship atuin)
        CAT_BINS=(starship atuin)
        CAT_DESCS=("Cross-shell prompt with git integration" "Searchable shell history synced across machines")
        CAT_CATEGORIES=(essential essential)
        CAT_REPLACES_LIST=("" "")
        CAT_BREWS=(starship atuin)
        CAT_APTS=(SCRIPT SCRIPT)
    fi
}

# Echoes the catalog index for a tool name, or -1 when unknown
find_catalog_index() {
    local name="$1" i
    for ((i = 0; i < ${#CAT_NAMES[@]}; i++)); do
        if [[ "${CAT_NAMES[$i]}" == "$name" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo -1
}

# ----------------------------------------------------------
# INTERACTIVE TOOL SELECTION (checkbox menu)
# Operates on MENU_* parallel arrays (bash 3.2: no assoc arrays).
# ----------------------------------------------------------

MENU_NAMES=()
MENU_DESCS=()
MENU_CATS=()
MENU_REPLACES=()
MENU_SEL=()

# Fills MENU_* from missing catalog tools, grouped essential->recommended->extra
build_tool_menu() {
    MENU_NAMES=() MENU_DESCS=() MENU_CATS=() MENU_REPLACES=() MENU_SEL=()
    local tier i
    for tier in essential recommended extra; do
        for ((i = 0; i < ${#CAT_NAMES[@]}; i++)); do
            [[ "${CAT_CATEGORIES[$i]}" == "$tier" ]] || continue
            has_cmd "${CAT_BINS[$i]}" && continue
            # Empty apt column marks macOS-only tools (e.g. mas)
            if ! is_macos && [[ -z "${CAT_APTS[$i]}" ]]; then
                continue
            fi
            MENU_NAMES+=("${CAT_NAMES[$i]}")
            MENU_DESCS+=("${CAT_DESCS[$i]}")
            MENU_CATS+=("$tier")
            MENU_REPLACES+=("${CAT_REPLACES_LIST[$i]:-}")
            MENU_SEL+=(0)
        done
    done
}

# Pre-checks MENU_SEL from the active INSTALL_PROFILE
apply_profile_preset() {
    local i
    for ((i = 0; i < ${#MENU_NAMES[@]}; i++)); do
        case "$INSTALL_PROFILE" in
            minimal)     [[ "${MENU_CATS[$i]}" == "essential" ]] && MENU_SEL[$i]=1 || MENU_SEL[$i]=0 ;;
            recommended) [[ "${MENU_CATS[$i]}" != "extra" ]] && MENU_SEL[$i]=1 || MENU_SEL[$i]=0 ;;
            full)        MENU_SEL[$i]=1 ;;
        esac
    done
}

render_tool_menu() {
    local i marker color group="" selected_count=0 num extra
    for ((i = 0; i < ${#MENU_SEL[@]}; i++)); do
        [[ "${MENU_SEL[$i]}" == "1" ]] && selected_count=$((selected_count + 1))
    done

    echo ""
    echo -e "  ${BOLD}Select tools to install${NC}  ${DIM}($selected_count of ${#MENU_NAMES[@]} selected · preset: $INSTALL_PROFILE)${NC}"
    for ((i = 0; i < ${#MENU_NAMES[@]}; i++)); do
        if [[ "${MENU_CATS[$i]}" != "$group" ]]; then
            group="${MENU_CATS[$i]}"
            case "$group" in
                essential)   color="$GREEN" ;;
                recommended) color="$CYAN" ;;
                *)           color="$YELLOW" ;;
            esac
            echo ""
            echo -e "  ${color}${BOLD}${group}${NC}"
        fi
        if [[ "${MENU_SEL[$i]}" == "1" ]]; then
            marker="${GREEN}[✓]${NC}"
        else
            marker="${DIM}[ ]${NC}"
        fi
        num=$(printf '%2d' "$((i + 1))")
        extra=""
        [[ -n "${MENU_REPLACES[$i]}" ]] && extra=" ${DIM}(replaces ${MENU_REPLACES[$i]})${NC}"
        echo -e "   $marker ${DIM}$num${NC}  ${WHITE}$(printf '%-10s' "${MENU_NAMES[$i]}")${NC} ${MENU_DESCS[$i]}$extra"
    done
    echo ""
    echo -e "  ${DIM}toggle numbers (e.g. 3 5 12) · ${NC}a${DIM}=all · ${NC}n${DIM}=none · ${NC}p${DIM}=cycle preset · ${NC}Enter${DIM}=confirm${NC}"
}

# Interactive loop; returns with MENU_SEL holding the final selection
select_tools_interactive() {
    apply_profile_preset

    local input tok i j
    while true; do
        render_tool_menu
        echo -ne "  ${YELLOW}?${NC} selection ${DIM}>${NC} "
        if ! { read -r input </dev/tty; } 2>/dev/null; then
            echo ""
            break
        fi
        case "$input" in
            "") break ;;
            a|A) for ((i = 0; i < ${#MENU_SEL[@]}; i++)); do MENU_SEL[$i]=1; done ;;
            n|N) for ((i = 0; i < ${#MENU_SEL[@]}; i++)); do MENU_SEL[$i]=0; done ;;
            p|P)
                case "$INSTALL_PROFILE" in
                    minimal)     INSTALL_PROFILE="recommended" ;;
                    recommended) INSTALL_PROFILE="full" ;;
                    *)           INSTALL_PROFILE="minimal" ;;
                esac
                apply_profile_preset
                ;;
            *)
                for tok in $input; do
                    if [[ "$tok" =~ ^[0-9]+$ ]] && [[ "$tok" -ge 1 && "$tok" -le ${#MENU_NAMES[@]} ]]; then
                        j=$((tok - 1))
                        if [[ "${MENU_SEL[$j]}" == "1" ]]; then
                            MENU_SEL[$j]=0
                        else
                            MENU_SEL[$j]=1
                        fi
                    else
                        echo -e "  ${RED}✗${NC} not a valid choice: $tok"
                    fi
                done
                ;;
        esac
    done
}

# Resolve a catalog index to a package spec for the given package manager.
# Echoes: a package name, SCRIPT:<tool>, CARGO:<crate>, or "" (unavailable).
resolve_package() {
    local idx="$1" pm="$2"
    local name="${CAT_NAMES[$idx]}" pkg=""

    case "$pm" in
        brew) pkg="${CAT_BREWS[$idx]}" ;;
        apt)  pkg="${CAT_APTS[$idx]}" ;;
        *)    pkg="$(get_package_name "$name" "$pm")" ;;
    esac

    [[ "$pkg" == "SCRIPT" ]] && pkg="SCRIPT:$name"
    echo "$pkg"
}

# Check if a tool should be installed based on profile and selection
should_install_tool() {
    local tool="$1"
    local category="$2"

    # If specific tools are selected via --tools, only install those
    if [[ -n "$SELECTED_TOOLS" ]]; then
        if [[ ",$SELECTED_TOOLS," == *",$tool,"* ]]; then
            return 0
        fi
        return 1
    fi

    # Profile-based selection
    case "$INSTALL_PROFILE" in
        minimal)
            # Only essential tools in minimal profile
            [[ "$category" == "essential" ]]
            ;;
        recommended)
            # Essential + recommended (skip extra)
            [[ "$category" == "essential" || "$category" == "recommended" ]]
            ;;
        full)
            return 0  # Install everything including extra
            ;;
    esac
}

install_optional_tools() {
    local pm
    pm=$(get_package_manager)

    # Skip entirely only with --skip-tools flag
    if $SKIP_TOOLS; then
        print_info "Skipping tools (--skip-tools)"
        return 0
    fi

    if [[ "$pm" == "none" ]]; then
        print_warning "No package manager available, skipping tools"
        return 0
    fi

    local -a missing=()
    local -a installed=()
    local -a to_install=()

    # Categorize tools from the shared catalog
    load_tool_catalog
    local i
    for ((i = 0; i < ${#CAT_NAMES[@]}; i++)); do
        # Empty apt column marks macOS-only tools (e.g. mas)
        if ! is_macos && [[ -z "${CAT_APTS[$i]}" ]]; then
            continue
        fi
        if has_cmd "${CAT_BINS[$i]}"; then
            installed+=("${CAT_NAMES[$i]}")
        else
            missing+=("${CAT_NAMES[$i]}:${CAT_BINS[$i]}:${CAT_DESCS[$i]}:${CAT_CATEGORIES[$i]}")
        fi
    done

    # Show already installed
    if [[ ${#installed[@]} -gt 0 ]]; then
        echo "  Already installed:"
        for tool in "${installed[@]}"; do
            print_success "$tool"
        done
    fi

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo ""
        print_success "All recommended tools are installed!"
        return 0
    fi

    # Interactive checkbox menu applies only when a human can drive it and
    # nothing on the command line already decided the selection
    local use_menu=false
    if [[ -z "$SELECTED_TOOLS" ]] && ! $AUTO_YES && ! $PROFILE_EXPLICIT && [[ -r /dev/tty ]]; then
        use_menu=true
    fi

    if [[ -n "$SELECTED_TOOLS" ]]; then
        # Specific tools selected via --tools flag
        echo ""
        print_info "Installing selected tools: $SELECTED_TOOLS"
        for entry in "${missing[@]}"; do
            local tool="${entry%%:*}"
            if [[ ",$SELECTED_TOOLS," == *",$tool,"* ]]; then
                to_install+=("$entry")
            fi
        done
    elif $use_menu; then
        # Checkbox menu over every missing catalog tool
        build_tool_menu
        select_tools_interactive
        local mi
        for ((mi = 0; mi < ${#MENU_NAMES[@]}; mi++)); do
            [[ "${MENU_SEL[$mi]}" == "1" ]] || continue
            for entry in "${missing[@]}"; do
                if [[ "${entry%%:*}" == "${MENU_NAMES[$mi]}" ]]; then
                    to_install+=("$entry")
                fi
            done
        done
    else
        # Unattended or explicit profile: category rules decide
        echo ""
        echo "  Missing tools:"
        echo ""
        for entry in "${missing[@]}"; do
            local tool="${entry%%:*}"
            local rest="${entry#*:}"
            rest="${rest#*:}"
            local desc="${rest%%:*}"
            local category="${rest#*:}"
            local marker="" pad=""
            case "$category" in
                essential)   marker="${GREEN}essential${NC}"; pad="  " ;;
                recommended) marker="${CYAN}recommended${NC}"; pad="" ;;
                extra)       marker="${YELLOW}extra${NC}"; pad="      " ;;
            esac
            local padded_tool
            padded_tool=$(printf '%-10s' "$tool")
            echo -e "    ${DIM}[${NC}${marker}${pad}${DIM}]${NC}  ${YELLOW}${padded_tool}${NC} ${desc}"

            if should_install_tool "$tool" "$category"; then
                to_install+=("$entry")
            fi
        done
        echo ""
        print_info "Profile '$INSTALL_PROFILE': installing ${#to_install[@]} of ${#missing[@]} missing tools"
    fi

    if [[ ${#to_install[@]} -eq 0 ]]; then
        print_info "No tools selected for installation"
        return 0
    fi

    local total_count=${#to_install[@]}
    local current=0
    echo ""
    print_info "Installing $total_count tools..."

    # Separate tools by install method
    local -a pm_install=()
    local -a special_install=()

    for entry in "${to_install[@]}"; do
        local tool="${entry%%:*}"
        local idx pkg_name
        idx=$(find_catalog_index "$tool")
        pkg_name=$(resolve_package "$idx" "$pm")

        if [[ -z "$pkg_name" ]]; then
            print_dim "  $tool is not available on this platform — skipped"
            continue
        elif [[ "$pkg_name" == CARGO:* ]] || [[ "$pkg_name" == SCRIPT:* ]]; then
            special_install+=("$pkg_name:$tool")
        else
            pm_install+=("$pkg_name:$tool")
        fi
    done

    # Track installation results
    local -a tools_success=()
    local -a tools_failed=()

    # Install via package manager
    if [[ ${#pm_install[@]} -gt 0 ]]; then
        # Update apt cache once before installing packages
        [[ "$pm" == "apt" ]] && maybe_sudo apt-get update -qq >/dev/null 2>&1

        for entry in "${pm_install[@]}"; do
            local pkg="${entry%%:*}"
            local tool="${entry#*:}"
            ((current++)) || true
            status "[$current/$total_count] Installing $tool..."

            if install_package_quiet "$pkg" "$pm"; then
                tools_success+=("$tool")
            else
                tools_failed+=("$tool")
            fi
        done
        status_clear
    fi

    # Install via special methods (cargo, scripts)
    if [[ ${#special_install[@]} -gt 0 ]]; then
        for entry in "${special_install[@]}"; do
            ((current++)) || true
            # Entry format: "SCRIPT:toolname:toolname" or "CARGO:toolname:toolname"
            # We need to extract "SCRIPT:toolname" for install_special_tool
            local tool="${entry##*:}"  # Get last segment (tool name)
            local method_pkg="${entry%:*}"  # Remove last segment (get METHOD:pkg)
            status "[$current/$total_count] Installing $tool..."

            if install_special_tool "$method_pkg"; then
                tools_success+=("$tool")
            else
                tools_failed+=("$tool")
            fi
        done
        status_clear
    fi

    # Show installation results summary
    echo ""
    echo "  Tool Installation Results:"
    if [[ ${#tools_success[@]} -gt 0 ]]; then
        for tool in "${tools_success[@]}"; do
            echo -e "    ${GREEN}✓${NC} $tool"
        done
    fi
    if [[ ${#tools_failed[@]} -gt 0 ]]; then
        for tool in "${tools_failed[@]}"; do
            echo -e "    ${RED}✗${NC} $tool (failed)"
        done
    fi
    echo ""

    if [[ ${#tools_failed[@]} -gt 0 ]]; then
        print_warning "${#tools_failed[@]} tool(s) failed to install"
        echo -e "  ${DIM}Run 'health' after installation to check status.${NC}"
    else
        print_success "All tools installed successfully"
    fi

    # Verify installations (refresh PATH and check)
    export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$PATH"
    local -a tools_verified=()
    local -a tools_not_found=()
    if [[ ${#tools_success[@]} -gt 0 ]]; then
        for tool in "${tools_success[@]}"; do
            local check_cmd="$tool"
            # Special cases: tool name != command name
            case "$tool" in
                ripgrep) check_cmd="rg" ;;
            esac
            if has_cmd "$check_cmd"; then
                tools_verified+=("$tool")
            else
                tools_not_found+=("$tool")
            fi
        done
    fi

    if [[ ${#tools_not_found[@]} -gt 0 ]]; then
        echo ""
        print_warning "Some tools installed but not yet in PATH:"
        for tool in "${tools_not_found[@]}"; do
            echo -e "    ${YELLOW}!${NC} $tool (will be available after shell restart)"
        done
    fi

    # Setup shell integrations for installed tools
    setup_shell_integrations
}

# ----------------------------------------------------------
# SHELL INTEGRATIONS
# Configures shell hooks for tools that need initialization
# ----------------------------------------------------------

# Helper: Add a shell integration to .zshlocal if not already present
add_integration() {
    local tool="$1" pattern="$2" comment="$3" cmd="$4"
    has_cmd "$tool" || return 1
    grep -q "$pattern" "$_LOCAL_CONFIG" 2>/dev/null && return 1
    { echo ""; echo "# $comment"; echo "$cmd"; } >> "$_LOCAL_CONFIG"
    print_success "Added $tool shell integration"
    return 0
}

setup_shell_integrations() {
    _LOCAL_CONFIG="$INSTALL_DIR/.zshlocal"
    local integrations_added=false

    # Check if .zshlocal exists and is writable
    [[ ! -f "$_LOCAL_CONFIG" ]] && return 0
    if [[ ! -w "$_LOCAL_CONFIG" ]]; then
        print_info "Skipping shell integrations (config is read-only)"
        print_dim "Add integrations manually to .zshlocal if needed"
        return 0
    fi

    # Add ~/.local/bin to PATH so we can find tools installed this session
    [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

    print_section "Shell Integrations"

    # Standard integrations
    add_integration "zoxide"   "zoxide init"   "Zoxide - smart directory jumping"  'eval "$(zoxide init zsh)"' && integrations_added=true
    add_integration "atuin"    "atuin init"    "Atuin - enhanced shell history"    'eval "$(atuin init zsh --disable-up-arrow)"' && integrations_added=true
    add_integration "starship" "starship init" "Starship - cross-shell prompt"     'eval "$(starship init zsh)"' && integrations_added=true && check_nerd_fonts

    # fzf needs special handling (two possible methods)
    if has_cmd fzf && ! grep -q "fzf --zsh\|\.fzf\.zsh" "$_LOCAL_CONFIG" 2>/dev/null; then
        if fzf --zsh &>/dev/null; then
            { echo ""; echo "# FZF - fuzzy finder integration"; echo 'source <(fzf --zsh)'; } >> "$_LOCAL_CONFIG"
        elif [[ -f "$HOME/.fzf.zsh" ]]; then
            { echo ""; echo "# FZF - fuzzy finder integration"; echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'; } >> "$_LOCAL_CONFIG"
        fi
        print_success "Added fzf shell integration"
        integrations_added=true
    fi

    $integrations_added || print_success "All shell integrations already configured"
}

# ----------------------------------------------------------
# TOOL CONFIGURATIONS
# Copies recommended tool configs with backup of existing
# ----------------------------------------------------------

install_tool_configs() {
    local tools_dir="$SCRIPT_DIR/tools"
    local manifest="$tools_dir/manifest.dat"
    [[ -f "$manifest" ]] || return 0

    print_section "Tool Configurations"
    load_tool_catalog

    local tool src dest mode installed_count=0
    while IFS=: read -r tool src dest mode; do
        case "$tool" in "#"*|"") continue ;; esac

        # Only configure tools that are actually present (catalog maps
        # names to binaries: ripgrep->rg, tldr->tldr, ...)
        local idx bin
        idx=$(find_catalog_index "$tool")
        bin="$tool"
        [[ "$idx" -ge 0 ]] && bin="${CAT_BINS[$idx]}"
        has_cmd "$bin" || continue

        if [[ ! -f "$tools_dir/$src" ]]; then
            print_warning "Config source missing for $tool: tools/$src"
            continue
        fi

        # Expand destination tokens
        local dest_path="$dest"
        dest_path="${dest_path//\$XDG_CONFIG_HOME/${XDG_CONFIG_HOME:-$HOME/.config}}"
        dest_path="${dest_path/#\~/$HOME}"

        if $DRY_RUN; then
            print_dim "[dry-run] install tools/$src -> $dest_path ($mode)"
            continue
        fi

        if [[ -f "$dest_path" ]]; then
            cp "$dest_path" "${dest_path}.backup"
            print_dim "Backed up existing ${dest_path##*/}"
        fi
        mkdir -p "$(dirname "$dest_path")"
        cp "$tools_dir/$src" "$dest_path"

        if [[ "$mode" == "gitinclude" ]] && has_cmd git; then
            # Idempotent: only add the include once
            if ! git config --global --get-all include.path 2>/dev/null | grep -Fqx "$dest_path"; then
                git config --global include.path "$dest_path"
                print_dim "Added $tool to git global include.path"
            fi
        fi

        print_success "Installed $tool config"
        installed_count=$((installed_count + 1))
    done < "$manifest"

    [[ $installed_count -eq 0 ]] && print_dim "No configurable tools present — nothing to do"
    return 0
}

# ----------------------------------------------------------
# NERD FONTS
# Checks and optionally installs Nerd Fonts for prompt icons
# ----------------------------------------------------------

check_nerd_fonts() {
    local dirs
    is_macos && dirs=("$HOME/Library/Fonts" "/Library/Fonts") \
             || dirs=("$HOME/.local/share/fonts" "$HOME/.fonts" "/usr/share/fonts" "/usr/local/share/fonts")

    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] && ls "$dir"/*Nerd* &>/dev/null 2>&1 && { print_success "Nerd Font detected"; return 0; }
    done

    print_warning "No Nerd Font detected - prompt icons may not display correctly"
    echo -e "\n  Starship uses Nerd Fonts for icons. Without one, you may see missing characters.\n"

    if ! $AUTO_YES && confirm "Install a Nerd Font (JetBrainsMono)?" "y"; then
        install_nerd_font
    else
        echo -e "  To install manually: https://www.nerdfonts.com/ (Recommended: JetBrainsMono)\n"
    fi
}

install_nerd_font() {
    local font_name="JetBrainsMono"
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" RETURN

    status "Downloading $font_name Nerd Font..."

    # Download font
    if ! fetch_with_retry "$font_url" "$tmp_dir/font.zip"; then
        status_clear
        print_error "Failed to download font"
        return 1
    fi

    status "Installing font..."

    # Ensure unzip is available
    if ! ensure_unzip; then
        status_clear
        print_warning "Skipping font installation (unzip required)"
        echo "  Install unzip manually and run: unzip font.zip -d ~/.local/share/fonts"
        return 0  # Non-fatal - continue installation
    fi

    # Determine font directory
    local font_dir
    if is_macos; then
        font_dir="$HOME/Library/Fonts"
    else
        font_dir="$HOME/.local/share/fonts"
    fi
    mkdir -p "$font_dir"

    # Extract only .ttf files (not Windows-compatible variants)
    unzip -q -o "$tmp_dir/font.zip" "*.ttf" -d "$font_dir" 2>/dev/null || \
    unzip -q -o "$tmp_dir/font.zip" -d "$font_dir" 2>/dev/null

    # Update font cache on Linux
    if is_linux && has_cmd fc-cache; then
        fc-cache -f "$font_dir" 2>/dev/null
    fi

    status_clear
    print_success "$font_name Nerd Font installed"
    echo ""
    echo -e "  ${YELLOW}Important:${NC} Restart your terminal and set the font in your"
    echo "  terminal preferences to '$font_name Nerd Font' or similar."
    echo ""
}

# ----------------------------------------------------------
# VERIFICATION
# ----------------------------------------------------------

verify_installation() {
    local all_good=true

    # Check ZDOTDIR is set
    if [[ -f "$HOME/.zshenv" ]] && grep -q "ZDOTDIR" "$HOME/.zshenv"; then
        print_success "ZDOTDIR configured in ~/.zshenv"
    else
        print_error "ZDOTDIR not configured"
        all_good=false
    fi

    # Check config directory exists
    if [[ -d "$INSTALL_DIR" ]] || [[ -L "$INSTALL_DIR" ]]; then
        print_success "Config directory exists: $INSTALL_DIR"
    else
        print_error "Config directory missing: $INSTALL_DIR"
        all_good=false
    fi

    # Check essential files
    local missing_files=0
    for file in "${ESSENTIAL_FILES[@]}"; do
        if [[ ! -f "$INSTALL_DIR/$file" ]]; then
            print_error "Missing: $file"
            ((missing_files++)) || true
            all_good=false
        fi
    done

    if [[ $missing_files -eq 0 ]]; then
        print_success "All essential files present"
    fi

    # Check plugins (optional UX layer — warn, never fail)
    if [[ -d "$DATA_DIR/zsh/plugins/zsh-autosuggestions" ]] || \
       [[ -d "$DATA_DIR/oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        print_success "Plugins installed"
    else
        print_warning "Plugins not found (shell works with reduced UX)"
    fi

    # Check XDG directories
    if [[ -d "$DATA_DIR/zsh" ]] && [[ -d "$CACHE_DIR/zsh" ]]; then
        print_success "XDG directories created"
    else
        print_warning "Some XDG directories missing"
    fi

    echo ""
    if $all_good; then
        print_success "Installation verified successfully!"
        return 0
    else
        print_error "Installation has issues - check errors above"
        return 1
    fi
}

# ----------------------------------------------------------
# FINAL SETUP
# ----------------------------------------------------------

create_local_config() {
    local local_config="$INSTALL_DIR/.zshlocal"

    if [[ -f "$local_config" ]]; then
        print_info ".zshlocal already exists"
        return 0
    fi

    if [[ -f "$INSTALL_DIR/examples/zshlocal" ]]; then
        if confirm "Create .zshlocal from example template?" "y"; then
            cp "$INSTALL_DIR/examples/zshlocal" "$local_config"
            print_success "Created .zshlocal"
            print_info "Edit with: \$EDITOR $local_config"
        fi
    fi
}

print_installation_failed() {
    local reason="$1"
    print_header "Installation Failed"
    echo -e "  ${RED}Installation could not complete.${NC}"
    echo ""
    if [[ -n "$reason" ]]; then
        echo -e "  ${RED}Reason:${NC} $reason"
        echo ""
    fi
    echo -e "  ${CYAN}What happened:${NC}"
    echo "    A critical component failed to install."
    echo "    Your system has been rolled back to its previous state."
    echo ""
    echo -e "  ${CYAN}Next steps:${NC}"
    echo "    1. Check your internet connection"
    echo "    2. Review the error messages above"
    echo "    3. Try running the installer again"
    echo "    4. If the issue persists, check: https://github.com/chiptoma/dotfiles-zsh/issues"
    echo ""
}

print_summary() {
    # Check if we have warnings (partial success)
    if [[ ${#INSTALL_WARNINGS[@]} -gt 0 ]]; then
        print_header "Installation Completed with Warnings"
        echo -e "  ${YELLOW}Core shell is functional but some features are missing.${NC}"
        echo ""
        for warning in "${INSTALL_WARNINGS[@]}"; do
            echo -e "    ${YELLOW}⚠${NC}  $warning"
        done
        echo ""
    else
        print_header "Installation Complete!"
        echo ""
    fi

    echo -e "  ${CYAN}${BOLD}Next Steps:${NC}"
    echo -e "    1. Run ${WHITE}exec zsh${NC} to start your new shell"
    echo -e "    2. Run ${WHITE}help${NC} to see available commands"
    echo -e "    3. Edit ${WHITE}$INSTALL_DIR/.zshlocal${NC} to customize"
    echo ""
    echo -e "  ${CYAN}${BOLD}Quick Reference:${NC}"
    echo -e "    ${WHITE}help${NC}    - Show quick reference guide"
    echo -e "    ${WHITE}status${NC}  - Show current configuration"
    echo -e "    ${WHITE}health${NC}  - Check for issues"
    echo ""

    # In curl-pipe mode, exec doesn't work (replaces subshell, not user's shell).
    # In unattended mode (--yes/CI/Ansible), never exec — it would hijack the
    # calling process and consume piped stdin as shell commands.
    if $CURL_PIPE_MODE || $AUTO_YES; then
        echo -e "  ${YELLOW}→${NC} Run ${WHITE}exec zsh${NC} to start using your new shell"
        echo ""
    elif confirm "Start a new ZSH shell now?" "y"; then
        exec zsh
    fi
}

# ----------------------------------------------------------
# UPDATE
# ----------------------------------------------------------

update() {
    print_header "Updating ZSH Configuration"

    local config_dir="${ZDOTDIR:-$INSTALL_DIR}"

    # Check if config directory exists
    if [[ ! -d "$config_dir" ]]; then
        print_error "Config directory not found: $config_dir"
        exit 1
    fi

    # Check if it's a git repository
    if [[ ! -d "$config_dir/.git" ]]; then
        # Check if it's a symlink to a git repo
        if [[ -L "$config_dir" ]]; then
            local target
            target=$(readlink "$config_dir")
            if [[ -d "$target/.git" ]]; then
                config_dir="$target"
            else
                print_error "Config is a symlink but not to a git repository"
                print_info "Update manually or re-clone the repository"
                exit 1
            fi
        else
            print_error "Config directory is not a git repository"
            print_info "Update manually or re-clone the repository"
            exit 1
        fi
    fi

    cd "$config_dir" || exit 1

    # Get current version
    local current_version="unknown"
    if [[ -f "version.txt" ]]; then
        current_version=$(cat version.txt)
    fi
    print_info "Current version: $current_version"

    # Check for uncommitted changes
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        print_warning "You have uncommitted changes"
        if ! confirm "Stash changes and continue?"; then
            exit 0
        fi
        git stash push -m "zsh-update-$(date +%Y%m%d_%H%M%S)"
        print_success "Changes stashed"
    fi

    # Fetch and pull
    print_info "Fetching updates..."
    if ! git fetch --tags 2>/dev/null; then
        print_error "Failed to fetch updates"
        exit 1
    fi

    local current_branch
    current_branch=$(git branch --show-current)
    local upstream="origin/$current_branch"

    # Check if there are updates
    local local_commit remote_commit
    local_commit=$(git rev-parse HEAD)
    remote_commit=$(git rev-parse "$upstream" 2>/dev/null || echo "")

    if [[ -z "$remote_commit" ]]; then
        print_warning "No upstream branch found"
        print_info "You may need to set upstream: git push -u origin $current_branch"
        exit 0
    fi

    if [[ "$local_commit" == "$remote_commit" ]]; then
        print_success "Already up to date!"
        exit 0
    fi

    # Show what's new
    print_info "Updates available:"
    git log --oneline HEAD.."$upstream" | head -10

    if ! confirm "Apply updates?" "y"; then
        exit 0
    fi

    # Pull updates
    if git pull --ff-only; then
        local new_version="unknown"
        if [[ -f "version.txt" ]]; then
            new_version=$(cat version.txt)
        fi
        print_success "Updated: $current_version -> $new_version"

        # Refresh plugin clones alongside the framework
        local plugins_dir="$DATA_DIR/zsh/plugins"
        local plugin
        for plugin in "$plugins_dir"/*/; do
            [[ -d "$plugin/.git" ]] || continue
            if git -C "$plugin" pull --ff-only --quiet 2>/dev/null; then
                print_dim "  Updated plugin: $(basename "$plugin")"
            fi
        done

        print_info "Restart your shell: exec zsh"
    else
        print_error "Update failed (merge conflict?)"
        print_info "Resolve manually or run: git pull"
        exit 1
    fi
}

# ----------------------------------------------------------
# REPAIR INSTALLATION
# ----------------------------------------------------------

repair_installation() {
    print_header "Repairing ZSH Installation"

    local issues_found=0
    local issues_fixed=0

    # Check 1: ZDOTDIR configuration
    print_section "Checking ZDOTDIR Configuration"
    if [[ ! -f "$HOME/.zshenv" ]]; then
        print_warning "~/.zshenv is missing"
        ((issues_found++)) || true
        if confirm "Create ~/.zshenv with ZDOTDIR?" "y"; then
            setup_zdotdir
            ((issues_fixed++)) || true
        fi
    elif ! grep -q "ZDOTDIR" "$HOME/.zshenv"; then
        print_warning "~/.zshenv exists but ZDOTDIR is not set"
        ((issues_found++)) || true
        if confirm "Add ZDOTDIR to ~/.zshenv?" "y"; then
            setup_zdotdir
            ((issues_fixed++)) || true
        fi
    else
        print_success "ZDOTDIR configured correctly"
    fi

    # Check 2: Config directory
    print_section "Checking Configuration Directory"
    if [[ ! -d "$INSTALL_DIR" && ! -L "$INSTALL_DIR" ]]; then
        print_warning "Config directory missing: $INSTALL_DIR"
        ((issues_found++)) || true
        if confirm "Re-install configuration?" "y"; then
            install_config
            ((issues_fixed++)) || true
        fi
    else
        print_success "Config directory exists"
    fi

    # Check 3: Essential files
    print_section "Checking Essential Files"
    for file in "${ESSENTIAL_FILES[@]}"; do
        if [[ ! -f "$INSTALL_DIR/$file" ]]; then
            print_error "Missing: $file"
            ((issues_found++)) || true
        fi
    done

    if [[ $issues_found -gt 0 ]] && [[ ! -f "$INSTALL_DIR/.zshrc" ]]; then
        print_warning "Essential files missing - configuration may be corrupted"
        if confirm "Re-install configuration from source?" "y"; then
            install_config
            ((issues_fixed++)) || true
        fi
    fi

    # Check 4: zsh plugins
    print_section "Checking Plugins"
    local plugins_dir="$DATA_DIR/zsh/plugins"
    local legacy_plugins_dir="$DATA_DIR/oh-my-zsh/custom/plugins"
    local -a required_plugins=(
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "fzf-tab"
    )

    local missing_plugins=0
    for plugin in "${required_plugins[@]}"; do
        if [[ ! -d "$plugins_dir/$plugin" && ! -d "$legacy_plugins_dir/$plugin" ]]; then
            print_warning "Missing plugin: $plugin"
            ((missing_plugins++)) || true
            ((issues_found++)) || true
        fi
    done

    if [[ $missing_plugins -gt 0 ]]; then
        if confirm "Install missing plugins?" "y"; then
            install_plugins
            ((issues_fixed++)) || true
        fi
    else
        print_success "All plugins installed"
    fi

    # Check 6: XDG directories
    print_section "Checking XDG Directories"
    local -a xdg_dirs=(
        "$DATA_DIR/zsh"
        "$CACHE_DIR/zsh"
        "$STATE_DIR/zsh"
    )

    for dir in "${xdg_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_warning "Missing directory: $dir"
            ((issues_found++)) || true
            mkdir -p "$dir"
            print_success "Created $dir"
            ((issues_fixed++)) || true
        fi
    done
    print_success "XDG directories OK"

    # Check 7: File permissions
    print_section "Checking File Permissions"
    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ ! -r "$INSTALL_DIR/.zshrc" ]]; then
            print_warning "Cannot read .zshrc - fixing permissions"
            ((issues_found++)) || true
            chmod u+r "$INSTALL_DIR/.zshrc" 2>/dev/null && ((issues_fixed++)) || true
        fi
    fi
    print_success "File permissions OK"

    # Summary
    print_section "Repair Summary"
    if [[ $issues_found -eq 0 ]]; then
        print_success "No issues found - installation is healthy!"
        return 0
    elif [[ $issues_fixed -eq $issues_found ]]; then
        print_success "All $issues_found issues have been fixed!"
        print_info "Restart your shell: exec zsh"
        return 0
    else
        local remaining=$((issues_found - issues_fixed))
        print_warning "$remaining of $issues_found issues could not be fixed automatically"
        echo ""
        echo "  Troubleshooting steps:"
        echo "    1. Try running: ./install.sh --uninstall && ./install.sh"
        echo "    2. Check file permissions in $INSTALL_DIR"
        echo "    3. Ensure you have write access to $HOME"
        echo ""
        return 1
    fi
}

# ----------------------------------------------------------
# UNINSTALL
# ----------------------------------------------------------

uninstall() {
    print_header "Uninstalling ZSH Configuration"

    # default y: reaching here already required an explicit --uninstall
    if confirm "This will remove the ZSH configuration. Continue?" "y"; then
        # Remove config
        if [[ -d "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
            rm -rf "$INSTALL_DIR"
            print_success "Removed $INSTALL_DIR"
        fi

        # Remove ZDOTDIR from .zshenv
        if [[ -f "$HOME/.zshenv" ]]; then
            rm -f "$HOME/.zshenv"
            print_success "Removed ~/.zshenv"
        fi

        # Ask about data directories
        if confirm "Remove data directories (history, cache)?"; then
            rm -rf "$DATA_DIR/zsh"
            rm -rf "$CACHE_DIR/zsh"
            rm -rf "$STATE_DIR/zsh"
            print_success "Removed data directories"
        fi

        # Offer to bring back the pre-install dotfiles
        # (|| true: no backups -> ls rc=2 would trip set -e + pipefail)
        local newest_backup
        newest_backup=$(ls -dt "$HOME"/.zsh-backup-* 2>/dev/null | head -1) || true
        if [[ -n "$newest_backup" ]] && confirm "Restore previous dotfiles from $newest_backup?" "n"; then
            restore_backup "$newest_backup"
        fi

        print_success "Uninstallation complete"
        print_info "Restart your shell or run: exec bash"
    fi
}

# ----------------------------------------------------------
# MAIN
# ----------------------------------------------------------

main() {
    # Save original arguments for curl-pipe re-exec
    local -a ORIGINAL_ARGS=("$@")

    # Initialize paths (must be first to pick up env overrides like custom HOME)
    init_paths

    # Maintenance action, dispatched AFTER the parse loop so flag order
    # never matters (--uninstall --yes must honor --yes)
    local ACTION=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall|-u)
                ACTION="uninstall"
                shift
                ;;
            --update)
                ACTION="update"
                shift
                ;;
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --quiet|-q)
                QUIET=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --skip-tools)
                SKIP_TOOLS=true
                shift
                ;;
            --symlink)
                INSTALL_METHOD="symlink"
                shift
                ;;
            --copy)
                INSTALL_METHOD="copy"
                shift
                ;;
            --default-shell)
                SET_DEFAULT_SHELL="yes"
                shift
                ;;
            --no-default-shell)
                SET_DEFAULT_SHELL="no"
                shift
                ;;
            --minimal)
                INSTALL_PROFILE="minimal"
                PROFILE_EXPLICIT=true
                shift
                ;;
            --full)
                INSTALL_PROFILE="full"
                PROFILE_EXPLICIT=true
                shift
                ;;
            --tools)
                # Comma-separated list of specific tools to install
                if [[ -z "${2:-}" ]]; then
                    print_error "--tools requires a comma-separated list (e.g., fzf,eza,bat)"
                    exit 2
                fi
                SELECTED_TOOLS="$2"
                shift 2
                ;;
            --repair|--fix)
                ACTION="repair"
                shift
                ;;
            --restore)
                ACTION="restore"
                # Optional argument: a specific backup directory
                if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                    RESTORE_DIR="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --user)
                # Switch to specified user (for Docker testing)
                if [[ -z "${2:-}" ]]; then
                    print_error "--user requires a username"
                    exit 2
                fi
                local target_user="$2"
                if ! id "$target_user" &>/dev/null; then
                    print_error "User '$target_user' does not exist"
                    exit 2
                fi
                print_info "Switching to user: $target_user"
                # Re-exec as target user with remaining args
                shift 2
                exec su - "$target_user" -c "cd '$SCRIPT_DIR' && ./install.sh $*"
                ;;
            --check|-c)
                ACTION="check"
                shift
                ;;
            --version|-v)
                echo "ZSH Dotfiles Installer v$VERSION"
                exit 0
                ;;
            --help|-h)
                echo "ZSH Dotfiles Installer v$VERSION"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Installation options:"
                echo "  --help, -h          Show this help message"
                echo "  --version, -v       Show version number"
                echo "  --yes, -y           Non-interactive mode (accept defaults)"
                echo "  --quiet, -q         Minimal output (implies --yes)"
                echo "  --dry-run, -n       Show what would be done without making changes"
                echo "  --verbose           Show detailed debug output"
                echo "  --symlink           Symlink the repo into place (development setups)"
                echo "  --copy              Copy files into place (default when unattended)"
                echo "  --default-shell     Set zsh as default shell without asking"
                echo "  --no-default-shell  Never touch the default shell"
                echo ""
                echo "Installation profiles:"
                echo "  --minimal           Core ZSH + plugins only (no optional tools)"
                echo "  --full              Install all optional tools automatically"
                echo "  --skip-tools        Skip optional tools installation step"
                echo "  --tools TOOLS       Install specific tools (comma-separated)"
                echo "                      Full catalog: lib/registry/tools.dat (starship, atuin,"
                echo "                      eza, bat, fzf, zoxide, delta, lazygit, btm, dust, ...)"
                echo ""
                echo "Maintenance:"
                echo "  --check, -c         Verify existing installation"
                echo "  --update            Update to latest version (git pull)"
                echo "  --repair, --fix     Repair broken installation"
                echo "  --restore [DIR]     Restore dotfiles from a backup (newest by default)"
                echo "  --uninstall, -u     Uninstall the configuration"
                echo ""
                echo "Advanced:"
                echo "  --user USERNAME     Run as specified user (for Docker testing)"
                echo ""
                echo "Environment:"
                echo "  NO_COLOR            Disable colored output"
                echo "  XDG_CONFIG_HOME     Override config directory (default: ~/.config)"
                echo "  XDG_DATA_HOME       Override data directory (default: ~/.local/share)"
                echo "  ZSH_DOTFILES_REPO_URL  Override repo URL for curl-pipe installs (forks/CI)"
                echo ""
                echo "Examples:"
                echo "  $0                        # Interactive installation"
                echo "  $0 --yes                  # Automated with defaults"
                echo "  $0 --minimal --yes        # Minimal install (no optional tools)"
                echo "  $0 --full --yes           # Full install with all tools"
                echo "  $0 --tools fzf,eza,bat    # Install only specific tools"
                echo "  $0 --skip-tools --yes     # Install config without optional tools"
                echo "  $0 --repair               # Fix broken installation"
                echo "  $0 --check                # Verify installation health"
                echo ""
                echo "Exit codes:"
                echo "  0  Success (warnings possible, listed in the summary)"
                echo "  1  Installation error (rollback attempted)"
                echo "  2  Usage error (bad flag or argument)"
                echo "  3  Preflight failure (missing dependency, no network)"
                echo ""
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 2
                ;;
        esac
    done

    # Quiet mode implies auto-yes
    if $QUIET; then
        AUTO_YES=true
    fi

    # Only force non-interactive mode if /dev/tty is unavailable (true CI/automation)
    # When /dev/tty exists, we can read from it even if stdin is piped
    if [[ ! -r /dev/tty ]] && ! $AUTO_YES; then
        AUTO_YES=true
        echo -e "  ${DIM}Non-interactive mode (no TTY available)${NC}"
        echo ""
    fi

    # Dispatch maintenance actions now that ALL flags are parsed
    case "$ACTION" in
        restore)
            local restore_from="${RESTORE_DIR:-}"
            if [[ -z "$restore_from" ]]; then
                # || true: no backups -> ls rc=2 would trip set -e + pipefail
                restore_from=$(ls -dt "$HOME"/.zsh-backup-* 2>/dev/null | head -1) || true
            fi
            if [[ -z "$restore_from" || ! -d "$restore_from" ]]; then
                print_error "No backup found to restore (looked for ~/.zsh-backup-*)"
                exit 1
            fi
            print_header "Restore From Backup"
            if confirm "Restore dotfiles from $restore_from (overwrites current files)?" "y"; then
                restore_backup "$restore_from"
            else
                print_info "Restore cancelled"
            fi
            exit 0
            ;;
        uninstall)
            uninstall
            exit 0
            ;;
        update)
            update
            exit 0
            ;;
        repair)
            repair_installation
            exit $?
            ;;
        check)
            print_header "ZSH Configuration Health Check"
            verify_installation
            exit $?
            ;;
    esac

    # Show logo and intro
    print_logo

    if $DRY_RUN; then
        echo -e "  ${YELLOW}${BOLD}DRY-RUN MODE${NC} - No changes will be made"
        echo ""
    fi

    if $VERBOSE; then
        echo -e "  ${DIM}VERBOSE MODE - Debug output enabled${NC}"
        echo ""
    fi

    # Handle curl-pipe mode: clone repo first
    if $CURL_PIPE_MODE; then
        echo -e "  ${CYAN}Detected curl-pipe installation${NC}"
        echo -e "  ${DIM}Cloning repository first...${NC}"
        echo ""

        local tmp_dir
        tmp_dir=$(mktemp -d)
        # ZSH_DOTFILES_REPO_URL: override for forks and offline/CI testing
        local repo_url="${ZSH_DOTFILES_REPO_URL:-https://github.com/chiptoma/dotfiles-zsh.git}"

        if ! git clone --depth=1 "$repo_url" "$tmp_dir" 2>/dev/null; then
            echo -e "  ${RED}✗ Failed to clone repository${NC}" >&2
            rm -rf "$tmp_dir"
            exit 1
        fi

        echo -e "  ${GREEN}✓ Repository cloned${NC}"
        echo ""

        # Re-exec the installer from the cloned repo with original arguments
        cd "$tmp_dir"
        exec bash "$tmp_dir/install.sh" "${ORIGINAL_ARGS[@]}"
    fi

    # Pre-install summary
    echo -e "  ${BOLD}This will:${NC}"
    echo -e "    • Create ${CYAN}~/.config/zsh/${NC} (your new config home)"
    echo -e "    • Modify ${CYAN}~/.zshenv${NC} (to set ZDOTDIR)"
    echo -e "    • Install zsh plugins to ${CYAN}~/.local/share/zsh/plugins/${NC}"
    if [[ "$INSTALL_PROFILE" != "minimal" ]] && ! $SKIP_TOOLS; then
        echo -e "    • Optionally install CLI tools (fzf, eza, etc.)"
    fi
    echo ""
    if [[ -f "$HOME/.zshrc" ]] || [[ -f "$HOME/.zshenv" ]]; then
        echo -e "  ${DIM}Your existing config will be backed up.${NC}"
        echo ""
    fi

    if ! confirm "Ready to install?" "y"; then
        echo "Installation cancelled."
        exit 0
    fi

    # Step 1: Pre-flight checks
    next_step "Pre-flight Checks"
    if ! preflight_checks; then
        exit 3
    fi

    # Step 2: System requirements
    next_step "Checking Requirements"
    check_requirements

    # Step 3: Plugins (optional UX layer — shell degrades gracefully)
    next_step "Plugin Setup"
    install_plugins

    # Step 4: Backup
    next_step "Backup Existing Configuration"
    backup_existing

    # Step 5: Installation (MANDATORY - shell breaks without it)
    next_step "Installing Configuration"
    if ! install_config; then
        print_installation_failed "Configuration installation failed"
        perform_rollback
        exit 1
    fi

    if ! setup_zdotdir; then
        print_installation_failed "ZDOTDIR setup failed - shell would not load new config"
        perform_rollback
        exit 1
    fi

    # Skip optional tools and local config in dry-run mode
    if ! $DRY_RUN; then
        # Step 6: Optional tools
        next_step "Optional Tools"
        # Create .zshlocal first (needed for shell integrations)
        create_local_config
        install_optional_tools
        install_tool_configs

        # Step 7: Verification & Finish
        next_step "Verification"
        verify_installation

        # Offer to set default shell
        print_section "Default Shell"
        offer_set_default_shell

        prune_old_backups
        print_summary
    else
        print_section "Dry-Run Complete"
        echo -e "  ${GREEN}No changes were made.${NC}"
        echo -e "  Run without --dry-run to perform actual installation."
        echo ""
    fi
}

# Source-guard: tests source this file to unit-test individual functions
if [[ -z "${BASH_SOURCE[0]:-}" || "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
