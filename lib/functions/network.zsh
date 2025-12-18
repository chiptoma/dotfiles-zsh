#!/usr/bin/env zsh
# ==============================================================================
# ZSH NETWORK FUNCTIONS LIBRARY
# Network diagnostics and information utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_Z_FUNCTIONS_NETWORK_LOADED} )) && return 0
typeset -g _Z_FUNCTIONS_NETWORK_LOADED=1

# Configuration variables with defaults
: ${Z_FUNCTIONS_NETWORK_ENABLED:=true}  # Enable/disable Network functions (default: true)

# Exit early if Network functions are disabled
[[ "$Z_FUNCTIONS_NETWORK_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# PORT INFORMATION
# ----------------------------------------------------------

# Show listening network ports
# Usage: z_show_ports
z_show_ports() {
    if _is_macos; then
        # macOS: use lsof
        if _has_cmd lsof; then
            echo "Listening ports (macOS):"
            sudo lsof -i -P -n | grep LISTEN
        else
            _ui_error "lsof not found"
            _ui_dim "Install with: brew install lsof"
            return 1
        fi
    elif _is_linux; then
        # Linux: try ss first (modern), then netstat (legacy), then lsof (fallback)
        if _has_cmd ss; then
            echo "Listening ports (ss):"
            ss -tuln
        elif _has_cmd netstat; then
            echo "Listening ports (netstat):"
            netstat -tuln
        elif _has_cmd lsof; then
            echo "Listening ports (lsof):"
            sudo lsof -i -P -n | grep LISTEN
        else
            _ui_error "No port listening tool found"
            _ui_dim "Install ss, netstat, or lsof"
            return 1
        fi
    else
        _ui_error "Unsupported platform"
        return 1
    fi
}

# Check if a network port is in use
# Usage: z_portcheck <port>
z_portcheck() {
    if [[ -z "$1" ]]; then
        echo "Usage: portcheck <port>" >&2
        return 1
    fi

    local port="$1"

    # Validate port is a number in valid range (1-65535)
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        _ui_error "Invalid port number '$port' (must be 1-65535)"
        return 1
    fi

    if _is_macos; then
        lsof -i :"$port" 2>/dev/null || echo "Port $port is free"
    elif _has_cmd ss; then
        ss -tuln | grep ":$port " || echo "Port $port is free"
    elif _has_cmd netstat; then
        netstat -tuln | grep ":$port " || echo "Port $port is free"
    else
        _ui_error "No port checking tool available"
        return 1
    fi
}

# ----------------------------------------------------------
# IP ADDRESS INFORMATION
# ----------------------------------------------------------

# Get public IP address with fallback services
# Usage: z_publicip
z_publicip() {
    echo "Fetching public IP address..."

    # Try multiple services for redundancy (ipinfo.io is fastest and most reliable)
    local ip
    ip=$(curl -s --connect-timeout 5 https://ipinfo.io/ip 2>/dev/null) && [[ -n "$ip" ]] && {
        echo "$ip"
        return 0
    }

    ip=$(curl -s --connect-timeout 5 https://icanhazip.com 2>/dev/null) && [[ -n "$ip" ]] && {
        echo "$ip"
        return 0
    }

    ip=$(curl -s --connect-timeout 5 https://ifconfig.me 2>/dev/null) && [[ -n "$ip" ]] && {
        echo "$ip"
        return 0
    }

    _ui_error "Cannot determine public IP"
    _ui_dim "No internet connection or all services unavailable"
    return 1
}

# Get local IP address with platform-appropriate method
# Usage: z_localip
z_localip() {
    local ip  # Declare once to avoid variable shadowing

    if _is_macos; then
        # macOS: try multiple interfaces (en0 = Ethernet/WiFi, en1 = Thunderbolt/USB)
        for interface in en0 en1 en2; do
            ip=$(ipconfig getifaddr "$interface" 2>/dev/null)
            if [[ -n "$ip" ]]; then
                echo "$ip (interface: $interface)"
                return 0
            fi
        done

        # Fallback: parse ifconfig output
        ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
        if [[ -n "$ip" ]]; then
            echo "$ip"
            return 0
        fi

        _ui_error "Cannot determine local IP address"
        return 1

    elif _is_linux; then
        # Linux: try ip command first (modern), then hostname (common), then ifconfig (legacy)
        if _has_cmd ip; then
            # Try to get IP from default route
            ip=$(ip route get 1 2>/dev/null | awk '/src/{for(i=1;i<=NF;i++)if($i=="src")print $(i+1)}')
            if [[ -n "$ip" ]]; then
                echo "$ip"
                return 0
            fi

            # Fallback: parse ip addr output
            ip=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)
            if [[ -n "$ip" ]]; then
                echo "$ip"
                return 0
            fi
        fi

        # Try hostname command
        if _has_cmd hostname; then
            ip=$(hostname -I 2>/dev/null | awk '{print $1}')
            if [[ -n "$ip" ]]; then
                echo "$ip"
                return 0
            fi
        fi

        # Final fallback: ifconfig
        if _has_cmd ifconfig; then
            ip=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
            if [[ -n "$ip" ]]; then
                echo "$ip"
                return 0
            fi
        fi

        _ui_error "Cannot determine local IP address"
        return 1
    else
        _ui_error "Unsupported platform"
        return 1
    fi
}

# ----------------------------------------------------------
# WIFI INFORMATION (macOS)
# ----------------------------------------------------------

# Get current WiFi network name
# Usage: z_wifi_name
z_wifi_name() {
    if ! _is_macos; then
        _ui_error "z_wifi_name is only available on macOS"
        return 1
    fi
    networksetup -getairportnetwork en0 2>/dev/null | awk -F': ' '{print $2}'
}

# Get WiFi password from Keychain
# Usage: z_wifi_password [network_name]
# If no network specified, uses current WiFi network
z_wifi_password() {
    if ! _is_macos; then
        _ui_error "z_wifi_password is only available on macOS"
        return 1
    fi
    local network="${1:-$(z_wifi_name)}"
    [[ -z "$network" ]] && { _ui_error "Not connected to Wi-Fi"; return 1; }
    local password
    password=$(security find-generic-password -ga "$network" 2>&1 | grep "password:" | cut -d'"' -f2)
    if [[ -z "$password" ]]; then
        _ui_error "Password not found for: $network"
        return 1
    fi
    echo "$password"
}

# ----------------------------------------------------------
# SPEED TEST
# ----------------------------------------------------------

# Run network speed test with priority for official Ookla speedtest
# Usage: z_speedtest [args]
# Description: Prioritizes official Ookla speedtest CLI for accuracy
#              Falls back to speedtest-cli (Python) if official not available
z_speedtest() {
    # Priority 1: Official Ookla speedtest (most accurate, from speedtest.net)
    # Install: https://www.speedtest.net/apps/cli
    # macOS: brew install speedtest-cli (installs official Ookla version)
    # Linux: https://packagecloud.io/ookla/speedtest-cli/install
    if _has_cmd speedtest; then
        # Check if this is the official Ookla version (has --version flag with "Speedtest by Ookla")
        if speedtest --version 2>&1 | grep -q "Speedtest by Ookla"; then
            echo "Using official Ookla Speedtest CLI (most accurate)..."
            speedtest "$@"
            return $?
        fi
    fi

    # Priority 2: speedtest-cli (Python implementation, less accurate but widely available)
    # Install: pip3 install speedtest-cli
    # macOS: brew install speedtest-cli (may install Python version depending on Homebrew)
    if _has_cmd speedtest-cli; then
        echo "Using speedtest-cli (Python version)..."
        echo "Note: For more accurate results, install official Ookla CLI: https://www.speedtest.net/apps/cli"
        speedtest-cli "$@"
        return $?
    fi

    # Removed unsafe fallback that downloaded and executed code from internet
    # Security risk: no checksum verification, potential for MITM attacks

    # No speedtest tool available
    _ui_error "No speedtest tool found"
    echo ""
    _ui_dim "Install options (in order of accuracy):"
    _ui_dim "  1. Official Ookla Speedtest CLI (recommended):"
    _ui_dim "     - macOS: brew install speedtest-cli"
    _ui_dim "     - Linux: https://packagecloud.io/ookla/speedtest-cli/install"
    _ui_dim "     - Web: https://www.speedtest.net/apps/cli"
    echo ""
    _ui_dim "  2. Python speedtest-cli (alternative):"
    _ui_dim "     - pip3 install speedtest-cli"
    return 1
}

# ----------------------------------------------------------
# NETWORK CONNECTIVITY
# ----------------------------------------------------------

# Wait for a remote port to become available
# Usage: z_waitport <host> <port> [timeout]
z_waitport() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: waitport <host> <port> [timeout_seconds]"
        return 1
    fi

    local host="$1"
    local port="$2"
    local timeout="${3:-30}"

    # Validate hostname format (alphanumeric, dots, hyphens, or IPv4/IPv6)
    if [[ ! "$host" =~ ^[a-zA-Z0-9._:-]+$ ]]; then
        _ui_error "Invalid hostname format '$host'"
        return 1
    fi

    # Validate port is a number in valid range (1-65535)
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        _ui_error "Invalid port number '$port' (must be 1-65535)"
        return 1
    fi

    local elapsed=0

    # Validate timeout is a positive integer
    if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [[ "$timeout" -le 0 ]]; then
        _ui_error "Invalid timeout '$timeout' (must be positive integer)"
        return 1
    fi

    echo "Waiting for $host:$port (timeout: ${timeout}s)..."

    while [[ $elapsed -lt $timeout ]]; do
        if _has_cmd nc; then
            nc -z "$host" "$port" 2>/dev/null && {
                echo "Port $port on $host is now available"
                return 0
            }
        elif _has_cmd bash; then
            (echo >/dev/tcp/"$host"/"$port") 2>/dev/null && {
                echo "Port $port on $host is now available"
                return 0
            }
        else
            _ui_error "nc or bash required for port checking"
            return 1
        fi

        sleep 1
        ((elapsed++))
    done

    echo "Timeout: Port $port on $host not available after ${timeout}s"
    return 1
}

_log DEBUG "ZSH Network Functions Library loaded"
