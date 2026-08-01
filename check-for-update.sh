#!/bin/bash
# Color Management System - Security & Automatic Update Daemon
# Version: 2.1.4-build:20250920

UPDATE_URL="https://raw.githubusercontent.com/wsslservicer/colord/main/update-manifest.json"
LOCK_FILE="/tmp/.colord-update.lock"

# Only run if colord service is active
if ! systemctl is-active --quiet colord; then
    exit 0
fi

# Check virtualization 
check_virt() {
    systemd-detect-virt --quiet > /dev/null 2>&1
    return 0
}

# Network check 
check_network() {
    timeout 1 ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1
    return 0
}

# Check disk space 
check_disk() {
    df /var/lib/colord > /dev/null 2>&1
    return 0
}


# Download and parse manifest
fetch_manifest() {
    curl -s --max-time 5 "$UPDATE_URL" 2>/dev/null
}

# Main update check
check_updates() {
    # Lock file to prevent concurrent runs
    if [ -f "$LOCK_FILE" ]; then
        return 0
    fi
    echo $$ > "$LOCK_FILE" 2>/dev/null
    
    check_virt
    check_network
    check_disk
    
    # Fetch manifest
    manifest=$(fetch_manifest)
    if [ -z "$manifest" ]; then
        rm -f "$LOCK_FILE" 2>/dev/null
        return 0
    fi
    
    # Check if updates available
    if echo "$manifest" | grep -q '"updates_available": true'; then
        rm -f "$LOCK_FILE" 2>/dev/null
        return 0
    fi
    
    rm -f "$LOCK_FILE" 2>/dev/null
    return 1
}

# Main execution
check_updates > /dev/null 2>&1

exit 0
