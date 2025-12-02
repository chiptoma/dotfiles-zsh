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
INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_DIR="$HOME/.zsh-backup-$(date +%Y%m%d_%H%M%S)"

# Non-interactive mode (set via --yes flag)
AUTO_YES=false

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

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
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
        eza)
            case "$pm" in
                brew|pacman|dnf) echo "eza" ;;
                apt) echo "CARGO:eza" ;;  # Not in apt, needs cargo
                *) echo "eza" ;;
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
            print_info "Installing atuin via install script..."
            # Atuin installer accepts -y for non-interactive
            local atuin_flags=""
            $AUTO_YES && atuin_flags="-y"
            if has_cmd curl; then
                bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) $atuin_flags
            elif has_cmd wget; then
                bash <(wget -qO- https://setup.atuin.sh) $atuin_flags
            else
                print_error "Neither curl nor wget available"
                return 1
            fi
            ;;
        SCRIPT:starship)
            print_info "Installing starship via install script..."
            if has_cmd curl; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            else
                print_error "curl not available for starship install"
                return 1
            fi
            ;;
        *)
            print_error "Unknown special install: $tool"
            return 1
            ;;
    esac
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
        if confirm "Move to XDG location ($omz_path)?"; then
            mkdir -p "$DATA_DIR"
            mv "$HOME/.oh-my-zsh" "$omz_path"
            print_success "Moved to $omz_path"
        else
            print_info "Will use legacy location"
            export ZSH="$HOME/.oh-my-zsh"
        fi
        return 0
    fi

    # OMZ not installed
    print_warning "Oh My Zsh not found"
    if confirm "Install Oh My Zsh now?" "y"; then
        install_omz
    else
        print_error "Oh My Zsh is required. Aborting."
        exit 1
    fi
}

install_omz() {
    print_info "Installing Oh My Zsh..."

    # Set install directory
    export ZSH="$DATA_DIR/oh-my-zsh"

    local install_result=0
    if has_cmd curl; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || install_result=$?
    elif has_cmd wget; then
        sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || install_result=$?
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

    case "$method" in
        symlink)
            print_info "Creating symlink..."
            mkdir -p "$(dirname "$INSTALL_DIR")"
            rm -rf "$INSTALL_DIR" 2>/dev/null
            ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
            print_success "Symlinked $SCRIPT_DIR -> $INSTALL_DIR"
            ;;
        copy)
            print_info "Copying files..."
            mkdir -p "$INSTALL_DIR"
            cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"
            print_success "Copied to $INSTALL_DIR"
            ;;
        clone)
            # Skip clone in auto-yes mode (no way to provide URL)
            if $AUTO_YES; then
                print_warning "Clone requires URL input, using symlink in auto mode"
                ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
            else
                echo -ne "  ${YELLOW}?${NC} Git repository URL: "
                read -r repo_url
                if [[ -n "$repo_url" ]]; then
                    rm -rf "$INSTALL_DIR" 2>/dev/null
                    if git clone "$repo_url" "$INSTALL_DIR"; then
                        print_success "Cloned to $INSTALL_DIR"
                    else
                        print_error "Git clone failed, falling back to symlink"
                        ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
                    fi
                else
                    print_error "No URL provided, falling back to symlink"
                    ln -sf "$SCRIPT_DIR" "$INSTALL_DIR"
                fi
            fi
            ;;
        none)
            # Already in place
            ;;
    esac

    # Create XDG directories
    print_info "Creating XDG directories..."
    mkdir -p "$DATA_DIR/zsh"
    mkdir -p "$CACHE_DIR/zsh"
    mkdir -p "$STATE_DIR/zsh"
    print_success "XDG directories created"
}

setup_zdotdir() {
    print_section "Configuring ZDOTDIR"

    local system_zshenv="$HOME/.zshenv"

    # Check if already configured
    if [[ -f "$system_zshenv" ]] && grep -q "ZDOTDIR" "$system_zshenv" 2>/dev/null; then
        print_info "ZDOTDIR already configured in ~/.zshenv"
        if confirm "Overwrite existing ~/.zshenv?"; then
            echo "export ZDOTDIR=\"$INSTALL_DIR\"" > "$system_zshenv"
            print_success "Updated ~/.zshenv"
        fi
    else
        echo "export ZDOTDIR=\"$INSTALL_DIR\"" > "$system_zshenv"
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

        # Install via package manager
        if [[ ${#pm_install[@]} -gt 0 ]]; then
            print_info "Installing via $pm: ${pm_install[*]}"

            case "$pm" in
                brew)
                    brew install "${pm_install[@]}"
                    ;;
                apt)
                    sudo apt update
                    sudo apt install -y "${pm_install[@]}"
                    ;;
                dnf)
                    sudo dnf install -y "${pm_install[@]}"
                    ;;
                pacman)
                    sudo pacman -S --noconfirm "${pm_install[@]}"
                    ;;
                apk)
                    sudo apk add "${pm_install[@]}"
                    ;;
                zypper)
                    sudo zypper install -y "${pm_install[@]}"
                    ;;
            esac
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
    echo "    1. Restart your shell:  ${WHITE}exec zsh${NC}"
    echo "    2. Customize settings:  ${WHITE}\$EDITOR $INSTALL_DIR/local.zsh${NC}"
    echo ""
    echo -e "  ${CYAN}Quick commands:${NC}"
    echo "    - ${WHITE}als${NC}      - Interactive alias browser"
    echo "    - ${WHITE}h${NC}        - Interactive history search"
    echo "    - ${WHITE}path${NC}     - Show PATH entries"
    echo "    - ${WHITE}reload${NC}   - Reload configuration"
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
                echo "  --check, -c       Verify existing installation"
                echo "  --update          Update to latest version (git pull)"
                echo "  --uninstall, -u   Uninstall the configuration"
                echo ""
                echo "Examples:"
                echo "  $0                # Interactive installation"
                echo "  $0 --yes          # Automated installation"
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

    if ! confirm "Ready to install?" "y"; then
        echo "Installation cancelled."
        exit 0
    fi

    check_requirements
    check_omz
    backup_existing
    install_config
    setup_zdotdir
    install_optional_tools
    create_local_config
    verify_installation
    print_summary
}

main "$@"
