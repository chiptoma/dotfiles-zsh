#!/usr/bin/env zsh
# ==============================================================================
# * ZSH NETWORK FUNCTIONS LIBRARY
# ? Network diagnostics and information utilities.
# ==============================================================================

# Idempotent guard - prevent multiple loads
(( ${+_ZSH_FUNCTIONS_NETWORK_LOADED} )) && return 0
typeset -g _ZSH_FUNCTIONS_NETWORK_LOADED=1

# Configuration variables with defaults
: ${ZSH_FUNCTIONS_NETWORK_ENABLED:=true}  # Enable/disable Network functions (default: true)

# Exit early if Network functions are disabled
[[ "$ZSH_FUNCTIONS_NETWORK_ENABLED" != "true" ]] && return 0

# ----------------------------------------------------------
# * PORT INFORMATION
# ----------------------------------------------------------

# Show listening network ports
# Usage: zsh_show_ports
zsh_show_ports() {
    if _is_macos; then
        # macOS: use lsof
        if _has_cmd lsof; then
            echo "Listening ports (macOS):"
            sudo lsof -i -P -n | grep LISTEN
        else
            echo "Error: lsof not found. Install with: brew install lsof" >&2
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
            echo "Error: No port listening tool found. Install ss, netstat, or lsof" >&2
            return 1
        fi
    else
        echo "Error: Unsupported platform" >&2
        return 1
    fi
}

# Check if a network port is in use
# Usage: zsh_portcheck <port>
zsh_portcheck() {
    if [[ -z "$1" ]]; then
        echo "Usage: portcheck <port>" >&2
        return 1
    fi

    local port="$1"

    # Validate port is a number in valid range (1-65535)
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        echo "Error: Invalid port number '$port' (must be 1-65535)" >&2
        return 1
    fi

    if _is_macos; then
        lsof -i :"$port" 2>/dev/null || echo "Port $port is free"
    elif _has_cmd ss; then
        ss -tuln | grep ":$port " || echo "Port $port is free"
    elif _has_cmd netstat; then
        netstat -tuln | grep ":$port " || echo "Port $port is free"
    else
        echo "Error: No port checking tool available" >&2
        return 1
    fi
}

# ----------------------------------------------------------
# * IP ADDRESS INFORMATION
# ----------------------------------------------------------

# Get public IP address with fallback services
# Usage: zsh_publicip
zsh_publicip() {
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

    echo "Error: Cannot determine public IP (no internet connection or all services unavailable)" >&2
    return 1
}

# Get local IP address with platform-appropriate method
# Usage: zsh_localip
zsh_localip() {
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

        echo "Error: Cannot determine local IP address" >&2
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

        echo "Error: Cannot determine local IP address" >&2
        return 1
    else
        echo "Error: Unsupported platform" >&2
        return 1
    fi
}

# ----------------------------------------------------------
# * SPEED TEST
# ----------------------------------------------------------

# Run network speed test with priority for official Ookla speedtest
# Usage: zsh_speedtest [args]
# Description: Prioritizes official Ookla speedtest CLI for accuracy
#              Falls back to speedtest-cli (Python) if official not available
zsh_speedtest() {
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

    # ! Removed unsafe fallback that downloaded and executed code from internet
    # ! Security risk: no checksum verification, potential for MITM attacks

    # No speedtest tool available
    echo "Error: No speedtest tool found" >&2
    echo ""
    echo "Install options (in order of accuracy):"
    echo "  1. Official Ookla Speedtest CLI (recommended):"
    echo "     - macOS: brew install speedtest-cli"
    echo "     - Linux: https://packagecloud.io/ookla/speedtest-cli/install"
    echo "     - Web: https://www.speedtest.net/apps/cli"
    echo ""
    echo "  2. Python speedtest-cli (alternative):"
    echo "     - pip3 install speedtest-cli"
    return 1
}

# ----------------------------------------------------------
# * NETWORK CONNECTIVITY
# ----------------------------------------------------------

# Wait for a remote port to become available
# Usage: zsh_waitport <host> <port> [timeout]
zsh_waitport() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: waitport <host> <port> [timeout_seconds]"
        return 1
    fi

    local host="$1"
    local port="$2"
    local timeout="${3:-30}"

    # ? Validate hostname format (alphanumeric, dots, hyphens, or IPv4/IPv6)
    if [[ ! "$host" =~ ^[a-zA-Z0-9._:-]+$ ]]; then
        echo "Error: Invalid hostname format '$host'" >&2
        return 1
    fi

    # Validate port is a number in valid range (1-65535)
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        echo "Error: Invalid port number '$port' (must be 1-65535)" >&2
        return 1
    fi

    local elapsed=0

    # Validate timeout is a positive integer
    if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [[ "$timeout" -le 0 ]]; then
        echo "Error: Invalid timeout '$timeout' (must be positive integer)" >&2
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
            echo "Error: nc or bash required for port checking" >&2
            return 1
        fi

        sleep 1
        ((elapsed++))
    done

    echo "Timeout: Port $port on $host not available after ${timeout}s"
    return 1
}

_log DEBUG "ZSH Network Functions Library loaded"
