#!/usr/bin/env bash
# ==============================================================================
# * ZSH DOTFILES INSTALLER
# ? Interactive installer for the ZSH configuration framework.
# ? Supports macOS and Linux with full cross-platform compatibility.
# ==============================================================================

set -euo pipefail

# ----------------------------------------------------------
# * CONFIGURATION
# ----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# These are initialized in init_paths() to ensure HOME is correct
INSTALL_DIR=""
DATA_DIR=""
CACHE_DIR=""
STATE_DIR=""
BACKUP_DIR=""

# Non-interactive mode (set via --yes flag)
AUTO_YES=false

# Dry-run mode (set via --dry-run flag)
DRY_RUN=false

# Initialize paths (call this at start of main to pick up env overrides)
init_paths() {
    INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
    STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
    BACKUP_DIR="$HOME/.zsh-backup-$(date +%Y%m%d_%H%M%S)"
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# ----------------------------------------------------------
# * HELPER FUNCTIONS
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
    read -r response

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

    echo -e "  ${YELLOW}?${NC} $prompt"
    local i=1
    for opt in "${options[@]}"; do
        echo -e "    ${CYAN}$i)${NC} $opt"
        ((i++))
    done
    echo -ne "  ${YELLOW}?${NC} Enter choice [1-${#options[@]}]: "
    read -r choice

    echo "$choice"
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

# Run command or show what would be done in dry-run mode
run_cmd() {
    if $DRY_RUN; then
        print_dim "[dry-run] $*"
    else
        "$@"
    fi
}

get_package_manager() {
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

# Get the correct package name for a tool on the current platform
# Some tools have different names in different package managers
get_package_name() {
    local tool="$1"
    local pm="$2"

    case "$tool" in
        fd)
            case "$pm" in
                brew|pacman|apk) echo "fd" ;;
                apt|dnf|yum|zypper) echo "fd-find" ;;
                *) echo "fd" ;;
            esac
            ;;
        ripgrep)
            echo "ripgrep"  # Same everywhere
            ;;
        bat)
            echo "bat"  # Same everywhere (batcat is just the binary name on Debian)
            ;;
        fzf)
            case "$pm" in
                brew|pacman|dnf) echo "fzf" ;;
                apt) echo "SCRIPT:fzf" ;;  # apt has old version, install from GitHub for --border-label support
                *) echo "fzf" ;;
            esac
            ;;
        eza)
            case "$pm" in
                brew|pacman|dnf) echo "eza" ;;
                apt) echo "SCRIPT:eza" ;;  # Not in apt, install from GitHub
                *) echo "eza" ;;
            esac
            ;;
        yazi)
            case "$pm" in
                brew|pacman) echo "yazi" ;;
                *) echo "SCRIPT:yazi" ;;  # Not in most repos, install from GitHub
            esac
            ;;
        atuin)
            case "$pm" in
                brew|pacman) echo "atuin" ;;
                *) echo "SCRIPT:atuin" ;;  # Needs install script
            esac
            ;;
        starship)
            case "$pm" in
                brew|pacman|dnf) echo "starship" ;;
                *) echo "SCRIPT:starship" ;;  # Needs install script
            esac
            ;;
        zoxide)
            case "$pm" in
                brew|pacman|dnf|apt) echo "zoxide" ;;
                *) echo "CARGO:zoxide" ;;
            esac
            ;;
        *)
            echo "$tool"
            ;;
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
            install_eza_binary
            ;;
        SCRIPT:fzf)
            print_info "Installing fzf..."
            install_fzf_binary
            ;;
        SCRIPT:yazi)
            print_info "Installing yazi..."
            install_yazi_binary
            ;;
        *)
            print_error "Unknown special install: $tool"
            return 1
            ;;
    esac
}

# Install eza from GitHub releases (for systems without package support)
install_eza_binary() {
    local arch
    arch=$(uname -m)
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture names
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *)
            print_warning "Unsupported architecture for eza: $arch"
            return 1
            ;;
    esac

    # Build download URL (eza uses gnu for Linux)
    local url="https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-${os}-gnu.tar.gz"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    # shellcheck disable=SC2064  # Intentional: capture current tmp_dir value
    trap "rm -rf '$tmp_dir'" RETURN

    # Download and extract
    if curl -fsSL "$url" | tar -xz -C "$tmp_dir" 2>/dev/null; then
        # Install to /usr/local/bin (or ~/.local/bin if no sudo)
        local install_dir="/usr/local/bin"
        if [[ ! -w "$install_dir" ]] && [[ $EUID -ne 0 ]]; then
            install_dir="$HOME/.local/bin"
            mkdir -p "$install_dir"
        fi

        if [[ -f "$tmp_dir/eza" ]]; then
            maybe_sudo install -m 755 "$tmp_dir/eza" "$install_dir/eza" 2>/dev/null
            if has_cmd eza || [[ -x "$install_dir/eza" ]]; then
                print_success "eza installed"
                return 0
            fi
        fi
    fi

    print_warning "Failed to install eza from GitHub"
    return 1
}

# Install fzf from GitHub releases (apt version is too old for --border-label)
install_fzf_binary() {
    local arch
    arch=$(uname -m)
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture names for fzf releases
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            print_warning "Unsupported architecture for fzf: $arch"
            return 1
            ;;
    esac

    # Get latest version from GitHub API (fzf includes version in filename)
    local version
    version=$(curl -fsSL "https://api.github.com/repos/junegunn/fzf/releases/latest" 2>/dev/null | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/')
    [[ -z "$version" ]] && version="0.56.3"  # Fallback

    # Build download URL with explicit version
    local url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${os}_${arch}.tar.gz"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    # shellcheck disable=SC2064  # Intentional: capture current tmp_dir value
    trap "rm -rf '$tmp_dir'" RETURN

    # Download and extract
    if curl -fsSL "$url" | tar -xz -C "$tmp_dir" 2>/dev/null; then
        local install_dir="/usr/local/bin"
        if [[ ! -w "$install_dir" ]] && [[ $EUID -ne 0 ]]; then
            install_dir="$HOME/.local/bin"
            mkdir -p "$install_dir"
        fi

        if [[ -f "$tmp_dir/fzf" ]]; then
            maybe_sudo install -m 755 "$tmp_dir/fzf" "$install_dir/fzf" 2>/dev/null
            if has_cmd fzf || [[ -x "$install_dir/fzf" ]]; then
                print_success "fzf installed"
                return 0
            fi
        fi
    fi

    print_warning "Failed to install fzf from GitHub"
    return 1
}

# Install yazi from GitHub releases
install_yazi_binary() {
    # yazi requires unzip
    if ! has_cmd unzip; then
        print_warning "yazi requires unzip (not installed)"
        return 1
    fi

    local arch
    arch=$(uname -m)
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture names for yazi releases
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *)
            print_warning "Unsupported architecture for yazi: $arch"
            return 1
            ;;
    esac

    # Build download URL (yazi uses musl for Linux)
    local url="https://github.com/sxyazi/yazi/releases/latest/download/yazi-${arch}-unknown-${os}-musl.zip"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    # shellcheck disable=SC2064  # Intentional: capture current tmp_dir value
    trap "rm -rf '$tmp_dir'" RETURN

    # Download and extract (yazi uses zip)
    if curl -fsSL "$url" -o "$tmp_dir/yazi.zip" 2>/dev/null && unzip -q "$tmp_dir/yazi.zip" -d "$tmp_dir" 2>/dev/null; then
        local install_dir="/usr/local/bin"
        if [[ ! -w "$install_dir" ]] && [[ $EUID -ne 0 ]]; then
            install_dir="$HOME/.local/bin"
            mkdir -p "$install_dir"
        fi

        # yazi extracts to a subdirectory
        local yazi_bin
        yazi_bin=$(find "$tmp_dir" -name "yazi" -type f -executable 2>/dev/null | head -1)
        if [[ -n "$yazi_bin" ]]; then
            maybe_sudo install -m 755 "$yazi_bin" "$install_dir/yazi" 2>/dev/null
            if has_cmd yazi || [[ -x "$install_dir/yazi" ]]; then
                print_success "yazi installed"
                return 0
            fi
        fi
    fi

    print_warning "Failed to install yazi from GitHub"
    return 1
}

# ----------------------------------------------------------
# * PRE-FLIGHT CHECKS
# ? Verify system requirements before installation
# ----------------------------------------------------------

preflight_checks() {
    print_section "Pre-flight Checks"

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

    if ! $all_good; then
        echo ""
        print_error "Pre-flight checks failed. Please resolve the issues above."
        return 1
    fi

    return 0
}

# ----------------------------------------------------------
# * SYSTEM CHECKS
# ----------------------------------------------------------

check_requirements() {
    print_section "Checking Requirements"

    local all_good=true

    # Check ZSH
    if has_cmd zsh; then
        local zsh_version
        zsh_version=$(zsh --version | awk '{print $2}')
        print_success "ZSH installed (version $zsh_version)"
    else
        print_error "ZSH not found"
        all_good=false
    fi

    # Check Git
    if has_cmd git; then
        local git_version
        git_version=$(git --version | awk '{print $3}')
        print_success "Git installed (version $git_version)"
    else
        print_error "Git not found"
        all_good=false
    fi

    # Check curl or wget
    if has_cmd curl; then
        print_success "curl installed"
    elif has_cmd wget; then
        print_success "wget installed"
    else
        print_warning "Neither curl nor wget found (needed for some features)"
    fi

    # Check package manager
    local pm
    pm=$(get_package_manager)
    if [[ "$pm" != "none" ]]; then
        print_success "Package manager: $pm"
    else
        print_warning "No supported package manager found"
    fi

    # Platform
    if is_macos; then
        print_info "Platform: macOS ($(uname -m))"
    elif is_linux; then
        local distro="unknown"
        if [[ -f /etc/os-release ]]; then
            distro=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
        fi
        print_info "Platform: Linux ($distro)"
    else
        print_warning "Platform: Unknown ($(uname -s))"
    fi

    if ! $all_good; then
        echo ""
        print_error "Missing required dependencies. Please install them first."
        exit 1
    fi
}

# ----------------------------------------------------------
# * OH MY ZSH
# ----------------------------------------------------------

check_omz() {
    print_section "Oh My Zsh"

    local omz_path="$DATA_DIR/oh-my-zsh"

    # Check common OMZ locations
    if [[ -d "$omz_path" ]]; then
        print_success "Oh My Zsh found at $omz_path"
        return 0
    elif [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_warning "Oh My Zsh found at ~/.oh-my-zsh (legacy location)"
        if confirm "Move to XDG location ($omz_path)?" "y"; then
            mkdir -p "$DATA_DIR"
            mv "$HOME/.oh-my-zsh" "$omz_path"
            print_success "Moved to $omz_path"
        else
            print_info "Will use legacy location"
            export ZSH="$HOME/.oh-my-zsh"
        fi
        return 0
    fi

    # OMZ not installed - auto-install (required dependency)
    print_info "Oh My Zsh not found - installing automatically..."
    install_omz
}

install_omz() {
    print_info "Installing Oh My Zsh..."

    # Set install directory
    export ZSH="$DATA_DIR/oh-my-zsh"

    local install_result=0
    # Suppress verbose OMZ installer output
    if has_cmd curl; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1 || install_result=$?
    elif has_cmd wget; then
        sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1 || install_result=$?
    else
        print_error "Neither curl nor wget available for OMZ install"
        return 1
    fi

    # Verify installation succeeded
    if [[ $install_result -ne 0 ]] || [[ ! -d "$ZSH" ]]; then
        print_error "Oh My Zsh installation failed"
        return 1
    fi

    # OMZ installer creates a new .zshrc, remove it
    rm -f "$HOME/.zshrc" 2>/dev/null

    print_success "Oh My Zsh installed"

    # Install required custom plugins
    install_omz_plugins
}

install_omz_plugins() {
    print_info "Installing OMZ plugins..."

    local custom_dir="${ZSH_CUSTOM:-$ZSH/custom}/plugins"
    mkdir -p "$custom_dir"

    # Required custom plugins (not bundled with OMZ)
    local -a plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
        "fzf-tab:https://github.com/Aloxaf/fzf-tab"
    )

    for entry in "${plugins[@]}"; do
        local name="${entry%%:*}"
        local url="${entry#*:}"
        local target="$custom_dir/$name"

        if [[ -d "$target" ]]; then
            print_dim "  $name (already installed)"
        else
            if git clone --depth=1 "$url" "$target" >/dev/null 2>&1; then
                print_success "$name"
            else
                print_warning "Failed to install $name"
            fi
        fi
    done
}

# ----------------------------------------------------------
# * BACKUP EXISTING CONFIG
# ----------------------------------------------------------

backup_existing() {
    print_section "Backing Up Existing Configuration"

    # Check for existing files
    local -a existing_files=()
    [[ -f "$HOME/.zshrc" ]] && existing_files+=("$HOME/.zshrc")
    [[ -f "$HOME/.zshenv" ]] && existing_files+=("$HOME/.zshenv")
    [[ -f "$HOME/.zprofile" ]] && existing_files+=("$HOME/.zprofile")
    [[ -d "$INSTALL_DIR" && "$INSTALL_DIR" != "$SCRIPT_DIR" ]] && existing_files+=("$INSTALL_DIR")

    if [[ ${#existing_files[@]} -eq 0 ]]; then
        print_success "No existing configuration to backup"
        return 0
    fi

    echo "  Found existing files:"
    for file in "${existing_files[@]}"; do
        print_dim "  - $file"
    done
    echo ""

    if confirm "Backup existing configuration?" "y"; then
        mkdir -p "$BACKUP_DIR"

        for file in "${existing_files[@]}"; do
            if [[ -e "$file" ]]; then
                local basename
                basename=$(basename "$file")
                cp -r "$file" "$BACKUP_DIR/$basename"
                print_success "Backed up: $file"
            fi
        done

        print_info "Backup location: $BACKUP_DIR"
    else
        print_warning "Skipping backup (existing files may be overwritten)"
    fi
}

# ----------------------------------------------------------
# * INSTALLATION
# ----------------------------------------------------------

install_config() {
    print_section "Installing Configuration"

    # Determine installation method
    local method
    if [[ "$SCRIPT_DIR" == "$INSTALL_DIR" ]]; then
        print_info "Already in target directory, no installation needed"
        method="none"
    else
        local choice
        choice=$(prompt_choice "How would you like to install?" "Symlink (recommended for development)" "Copy files" "Clone from Git repository")

        case "$choice" in
            1) method="symlink" ;;
            2) method="copy" ;;
            3) method="clone" ;;
            *) method="symlink" ;;
        esac
    fi

    # Atomic installation: use temp directory, verify, then move
    local temp_install=""

    case "$method" in
        symlink)
            print_info "Creating symlink..."
            if $DRY_RUN; then
                print_dim "[dry-run] mkdir -p $(dirname "$INSTALL_DIR")"
                print_dim "[dry-run] rm -rf $INSTALL_DIR"
                print_dim "[dry-run] ln -sf $SCRIPT_DIR $INSTALL_DIR"
            else
                mkdir -p "$(dirname "$INSTALL_DIR")"
                rm -rf "$INSTALL_DIR" 2>/dev/null
                ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
            fi
            print_success "Symlinked $SCRIPT_DIR -> $INSTALL_DIR"
            ;;
        copy)
            print_info "Copying files (atomic)..."
            if $DRY_RUN; then
                print_dim "[dry-run] mkdir -p $INSTALL_DIR.tmp.$$"
                print_dim "[dry-run] cp -r $SCRIPT_DIR/* $INSTALL_DIR.tmp.$$/"
                print_dim "[dry-run] verify essential files"
                print_dim "[dry-run] rm -rf $INSTALL_DIR"
                print_dim "[dry-run] mv $INSTALL_DIR.tmp.$$ $INSTALL_DIR"
            else
                temp_install="$INSTALL_DIR.tmp.$$"

                # Copy to temp location
                mkdir -p "$temp_install"
                if ! cp -r "$SCRIPT_DIR"/* "$temp_install/"; then
                    print_error "Failed to copy files"
                    rm -rf "$temp_install"
                    return 1
                fi

                # Verify essential files exist in temp
                local -a essential=(".zshenv" ".zshrc" "modules/logging.zsh" "lib/utils.zsh")
                for file in "${essential[@]}"; do
                    if [[ ! -f "$temp_install/$file" ]]; then
                        print_error "Essential file missing in copy: $file"
                        rm -rf "$temp_install"
                        return 1
                    fi
                done

                # Atomic swap: remove old, move new
                rm -rf "$INSTALL_DIR" 2>/dev/null
                if ! mv "$temp_install" "$INSTALL_DIR"; then
                    print_error "Failed to move files to final location"
                    # Attempt recovery
                    if [[ -d "$temp_install" ]]; then
                        mv "$temp_install" "$INSTALL_DIR" 2>/dev/null || true
                    fi
                    return 1
                fi
            fi
            print_success "Copied to $INSTALL_DIR"
            ;;
        clone)
            # Skip clone in auto-yes mode (no way to provide URL)
            if $AUTO_YES; then
                print_warning "Clone requires URL input, using symlink in auto mode"
                if ! $DRY_RUN; then
                    ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
                fi
            else
                echo -ne "  ${YELLOW}?${NC} Git repository URL: "
                read -r repo_url
                if [[ -n "$repo_url" ]]; then
                    if $DRY_RUN; then
                        print_dim "[dry-run] rm -rf $INSTALL_DIR"
                        print_dim "[dry-run] git clone $repo_url $INSTALL_DIR"
                    else
                        rm -rf "$INSTALL_DIR" 2>/dev/null
                        if git clone "$repo_url" "$INSTALL_DIR"; then
                            print_success "Cloned to $INSTALL_DIR"
                        else
                            print_error "Git clone failed, falling back to symlink"
                            ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
                        fi
                    fi
                else
                    print_error "No URL provided, falling back to symlink"
                    if ! $DRY_RUN; then
                        ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
                    fi
                fi
            fi
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
    print_section "Configuring ZDOTDIR"

    local system_zshenv="$HOME/.zshenv"

    # ? ZSH doesn't auto-source $ZDOTDIR/.zshenv after ZDOTDIR is set mid-file,
    # ? so we must explicitly source it to load utils, logging, etc.
    local zshenv_content
    zshenv_content="export ZDOTDIR=\"$INSTALL_DIR\"
[[ -r \"\$ZDOTDIR/.zshenv\" ]] && source \"\$ZDOTDIR/.zshenv\""

    # Check if already configured
    if [[ -f "$system_zshenv" ]] && grep -q "ZDOTDIR" "$system_zshenv" 2>/dev/null; then
        print_info "ZDOTDIR already configured in ~/.zshenv"
        if confirm "Overwrite existing ~/.zshenv?"; then
            if $DRY_RUN; then
                print_dim "[dry-run] Writing ZDOTDIR config to $system_zshenv"
            else
                printf '%s\n' "$zshenv_content" > "$system_zshenv"
            fi
            print_success "Updated ~/.zshenv"
        fi
    else
        if $DRY_RUN; then
            print_dim "[dry-run] Writing ZDOTDIR config to $system_zshenv"
        else
            printf '%s\n' "$zshenv_content" > "$system_zshenv"
        fi
        print_success "Created ~/.zshenv with ZDOTDIR"
    fi
}

# ----------------------------------------------------------
# * OPTIONAL TOOLS
# ----------------------------------------------------------

install_optional_tools() {
    print_section "Optional Tools"

    local pm
    pm=$(get_package_manager)

    if [[ "$pm" == "none" ]]; then
        print_warning "No package manager available, skipping optional tools"
        return 0
    fi

    # Tools with descriptions and command names for checking
    # Format: "tool:command:description"
    local -a tools=(
        "fzf:fzf:Fuzzy finder for history search"
        "eza:eza:Modern ls replacement"
        "bat:bat:Better cat with syntax highlighting"
        "ripgrep:rg:Fast grep replacement"
        "fd:fd:Modern find replacement"
        "zoxide:zoxide:Smart directory jumping"
        "yazi:yazi:Terminal file manager"
        "starship:starship:Cross-shell prompt"
        "atuin:atuin:Shell history sync and search"
    )

    local -a missing=()
    local -a installed=()

    for entry in "${tools[@]}"; do
        local tool="${entry%%:*}"
        local rest="${entry#*:}"
        local check_cmd="${rest%%:*}"
        local desc="${rest#*:}"

        if has_cmd "$check_cmd"; then
            installed+=("$tool")
        else
            missing+=("$tool:$desc")
        fi
    done

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

    echo ""
    echo "  Missing tools:"
    for entry in "${missing[@]}"; do
        local tool="${entry%%:*}"
        local desc="${entry#*:}"
        print_warning "$tool - $desc"
    done

    echo ""
    if confirm "Install missing tools?" "y"; then
        # Separate tools by install method
        local -a pm_install=()      # Install via package manager
        local -a special_install=() # Install via script/cargo

        for entry in "${missing[@]}"; do
            local tool="${entry%%:*}"
            local pkg_name
            pkg_name=$(get_package_name "$tool" "$pm")

            if [[ "$pkg_name" == CARGO:* ]] || [[ "$pkg_name" == SCRIPT:* ]]; then
                special_install+=("$pkg_name")
            else
                pm_install+=("$pkg_name")
            fi
        done

        # Install via package manager (non-fatal - optional tools)
        if [[ ${#pm_install[@]} -gt 0 ]]; then
            print_info "Installing via $pm: ${pm_install[*]}"

            # Package installation is optional - don't fail if some packages unavailable
            # Suppress verbose output but capture errors
            case "$pm" in
                brew)
                    brew install "${pm_install[@]}" >/dev/null 2>&1 || print_warning "Some packages failed to install"
                    ;;
                apt)
                    maybe_sudo apt-get update -qq >/dev/null 2>&1
                    # Also install unzip (needed for yazi) if not present
                    maybe_sudo apt-get install -qq -y unzip "${pm_install[@]}" >/dev/null 2>&1 || print_warning "Some packages failed to install"
                    ;;
                dnf)
                    maybe_sudo dnf install -y -q --skip-unavailable "${pm_install[@]}" >/dev/null 2>&1 || print_warning "Some packages failed to install"
                    ;;
                pacman)
                    maybe_sudo pacman -S --noconfirm --needed -q "${pm_install[@]}" >/dev/null 2>&1 || print_warning "Some packages failed to install"
                    ;;
                apk)
                    maybe_sudo apk add -q "${pm_install[@]}" >/dev/null 2>&1 || print_warning "Some packages failed to install"
                    ;;
                zypper)
                    maybe_sudo zypper install -y -q "${pm_install[@]}" >/dev/null 2>&1 || print_warning "Some packages failed to install"
                    ;;
            esac
            print_success "Package manager tools installed"
        fi

        # Install via special methods (cargo, scripts)
        if [[ ${#special_install[@]} -gt 0 ]]; then
            for special in "${special_install[@]}"; do
                install_special_tool "$special" || true
            done
        fi

        print_success "Tool installation complete"
    fi
}

# ----------------------------------------------------------
# * VERIFICATION
# ----------------------------------------------------------

verify_installation() {
    print_section "Verifying Installation"

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
    local -a essential_files=(
        ".zshenv"
        ".zshrc"
        "modules/logging.zsh"
        "lib/utils.zsh"
    )

    local missing_files=0
    for file in "${essential_files[@]}"; do
        if [[ ! -f "$INSTALL_DIR/$file" ]]; then
            print_error "Missing: $file"
            ((missing_files++))
            all_good=false
        fi
    done

    if [[ $missing_files -eq 0 ]]; then
        print_success "All essential files present"
    fi

    # Check Oh My Zsh
    if [[ -d "$DATA_DIR/oh-my-zsh" ]] || [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh installed"
    else
        print_error "Oh My Zsh not found"
        all_good=false
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
# * FINAL SETUP
# ----------------------------------------------------------

create_local_config() {
    print_section "Local Configuration"

    local local_config="$INSTALL_DIR/local.zsh"

    if [[ -f "$local_config" ]]; then
        print_info "local.zsh already exists"
        return 0
    fi

    if [[ -f "$INSTALL_DIR/local.zsh.example" ]]; then
        if confirm "Create local.zsh from example template?" "y"; then
            cp "$INSTALL_DIR/local.zsh.example" "$local_config"
            print_success "Created local.zsh"
            print_info "Edit with: \$EDITOR $local_config"
        fi
    fi
}

print_summary() {
    print_header "Installation Complete!"

    echo -e "  ${GREEN}Your ZSH configuration has been installed successfully.${NC}"
    echo ""
    echo "  Configuration location: $INSTALL_DIR"
    echo "  Data directory:         $DATA_DIR/zsh"
    echo "  Cache directory:        $CACHE_DIR/zsh"
    if [[ -d "$BACKUP_DIR" ]]; then
        echo "  Backup location:        $BACKUP_DIR"
    fi
    echo ""
    echo -e "  ${CYAN}Next steps:${NC}"
    echo -e "    1. Restart your shell:  ${WHITE}exec zsh${NC}"
    echo -e "    2. Customize settings:  ${WHITE}\$EDITOR $INSTALL_DIR/local.zsh${NC}"
    echo ""
    echo -e "  ${CYAN}Quick commands:${NC}"
    echo -e "    - ${WHITE}als${NC}      - Interactive alias browser"
    echo -e "    - ${WHITE}h${NC}        - Interactive history search"
    echo -e "    - ${WHITE}path${NC}     - Show PATH entries"
    echo -e "    - ${WHITE}reload${NC}   - Reload configuration"
    echo ""
    echo -e "  ${DIM}Documentation: https://github.com/chiptoma/dotfiles-zsh${NC}"
    echo ""

    if confirm "Start a new ZSH shell now?" "y"; then
        exec zsh
    fi
}

# ----------------------------------------------------------
# * UPDATE
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
    if [[ -f "VERSION" ]]; then
        current_version=$(cat VERSION)
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
        if [[ -f "VERSION" ]]; then
            new_version=$(cat VERSION)
        fi
        print_success "Updated: $current_version -> $new_version"
        print_info "Restart your shell: exec zsh"
    else
        print_error "Update failed (merge conflict?)"
        print_info "Resolve manually or run: git pull"
        exit 1
    fi
}

# ----------------------------------------------------------
# * UNINSTALL
# ----------------------------------------------------------

uninstall() {
    print_header "Uninstalling ZSH Configuration"

    if confirm "This will remove the ZSH configuration. Continue?"; then
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

        print_success "Uninstallation complete"
        print_info "Restart your shell or run: exec bash"
    fi
}

# ----------------------------------------------------------
# * MAIN
# ----------------------------------------------------------

main() {
    # Initialize paths (must be first to pick up env overrides like custom HOME)
    init_paths

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall|-u)
                uninstall
                exit 0
                ;;
            --update)
                update
                exit 0
                ;;
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --check|-c)
                print_header "ZSH Configuration Health Check"
                verify_installation
                exit $?
                ;;
            --help|-h)
                echo "ZSH Dotfiles Installer"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --help, -h        Show this help message"
                echo "  --yes, -y         Non-interactive mode (accept defaults)"
                echo "  --dry-run, -n     Show what would be done without making changes"
                echo "  --check, -c       Verify existing installation"
                echo "  --update          Update to latest version (git pull)"
                echo "  --uninstall, -u   Uninstall the configuration"
                echo ""
                echo "Examples:"
                echo "  $0                # Interactive installation"
                echo "  $0 --yes          # Automated installation"
                echo "  $0 --dry-run      # Preview installation steps"
                echo "  $0 --check        # Verify installation health"
                echo "  $0 --update       # Update to latest version"
                echo ""
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    print_header "ZSH Configuration Installer"

    echo -e "  ${DIM}A modern, modular ZSH configuration framework${NC}"
    echo -e "  ${DIM}with security hardening, lazy loading, and cross-platform support.${NC}"
    echo ""

    if $DRY_RUN; then
        echo -e "  ${YELLOW}${BOLD}DRY-RUN MODE${NC} - No changes will be made"
        echo ""
    fi

    if ! confirm "Ready to install?" "y"; then
        echo "Installation cancelled."
        exit 0
    fi

    # Pre-flight checks
    if ! preflight_checks; then
        exit 1
    fi

    check_requirements
    check_omz
    backup_existing
    install_config
    setup_zdotdir

    # Skip optional tools and local config in dry-run mode
    if ! $DRY_RUN; then
        install_optional_tools
        create_local_config
        verify_installation
        print_summary
    else
        print_section "Dry-Run Complete"
        echo -e "  ${GREEN}No changes were made.${NC}"
        echo -e "  Run without --dry-run to perform actual installation."
        echo ""
    fi
}

main "$@"
