#!/bin/bash

set -euo pipefail

# Konfiguration
NETBIRD_BIN="/usr/bin/netbird"
MIN_PEERS=${MIN_PEERS:-3}
LOG_FILE="/var/log/netbird-monitor.log"
STATUS_TIMEOUT=10

# Logging-Funktion
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $level: $message" | tee -a "$LOG_FILE"
    logger -t netbird-monitor "$level: $message"
}

# Prüfen ob NetBird-Service enabled ist
is_netbird_enabled() {
    if systemctl is-enabled --quiet netbird 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# NetBird-Status prüfen
get_netbird_status() {
    local status_output
    local exit_code=0

    # Status mit Timeout abrufen
    status_output=$(timeout "$STATUS_TIMEOUT" "$NETBIRD_BIN" status 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log "DEBUG" "NetBird status command failed (exit code: $exit_code)"
        return 1
    fi
        
    echo "$status_output"
    return 0
}

# Peers aus Status-Output extrahieren
parse_peer_count() {
    local status_output="$1"
    local connected_peers=0
    local total_peers=0

    # Verschiedene Ausgabeformate prüfen
    if echo "$status_output" | grep -q "Peers count:"; then
        # Format: "Peers count: 7/8"
        local peer_line=$(echo "$status_output" | grep "Peers count:" | head -1)
        if [[ $peer_line =~ ([0-9]+)/([0-9]+) ]]; then
            connected_peers=${BASH_REMATCH[1]}
            total_peers=${BASH_REMATCH[2]}
        fi
    elif echo "$status_output" | grep -q "Connected peers:"; then
        # Format: "Connected peers: 7/8"
        local peer_line=$(echo "$status_output" | grep "Connected peers:" | head -1)
        if [[ $peer_line =~ ([0-9]+)/([0-9]+) ]]; then
            connected_peers=${BASH_REMATCH[1]}
            total_peers=${BASH_REMATCH[2]}
        fi
    elif echo "$status_output" | grep -qE "[0-9]+/[0-9]+"; then
        # Fallback: Nach Zahlen-Pattern suchen
        local numbers=$(echo "$status_output" | grep -oE "[0-9]+/[0-9]+" | head -1)
        if [[ $numbers =~ ([0-9]+)/([0-9]+) ]]; then
            connected_peers=${BASH_REMATCH[1]}
            total_peers=${BASH_REMATCH[2]}
        fi
    fi
        
    # Validierung
    if [[ $connected_peers -eq 0 && $total_peers -eq 0 ]]; then
        return 1
    fi

    echo "$connected_peers/$total_peers"
    return 0
}

# NetBird up ausführen
netbird_up() {
    log "INFO" "Executing 'netbird up'..."

    if "$NETBIRD_BIN" up 2>&1 | tee -a "$LOG_FILE"; then
        log "INFO" "NetBird up command completed"
        return 0
    else
        log "ERROR" "NetBird up command failed"
        return 1
    fi
}

# Hauptfunktion
main() {
    log "INFO" "NetBird monitor started"
        
    # Prüfen ob NetBird-Service enabled ist
    if ! is_netbird_enabled; then
        log "INFO" "NetBird service is disabled - monitoring skipped"
        log "INFO" "NetBird monitor finished"
        exit 0
    fi
        
    log "DEBUG" "NetBird service is enabled - proceeding with monitoring"

    # NetBird-Status abrufen
    local status_output
    if ! status_output=$(get_netbird_status); then
        log "WARNING" "Cannot get NetBird status - NetBird appears to be down"

        # NetBird up versuchen
        if netbird_up; then
            log "INFO" "NetBird up executed successfully"
        else
            log "ERROR" "NetBird up failed"
        fi

        log "INFO" "NetBird monitor finished"
        exit 0
    fi

    # Peer-Count extrahieren
    local peer_info
    if ! peer_info=$(parse_peer_count "$status_output"); then
        log "ERROR" "Could not find peers count in status output"
        log "DEBUG" "Status output was: $status_output"

        # NetBird up versuchen
        if netbird_up; then
            log "INFO" "NetBird up executed due to parsing error"
        fi

        log "INFO" "NetBird monitor finished"
        exit 0
    fi
    
    # Peer-Zahlen aufteilen
    local connected_peers total_peers
    IFS='/' read -r connected_peers total_peers <<< "$peer_info"

    log "INFO" "Connected peers: $connected_peers/$total_peers"

    # Peer-Count prüfen
    if [[ $connected_peers -lt $MIN_PEERS ]]; then
        log "WARNING" "Only $connected_peers peers connected (minimum: $MIN_PEERS). Executing 'netbird up'..."

        if netbird_up; then
            log "INFO" "NetBird up executed successfully"
        else
            log "ERROR" "NetBird up failed"
        fi
    else
        log "INFO" "NetBird status OK ($connected_peers/$total_peers peers)"
    fi
        
    log "INFO" "NetBird monitor finished"
}       
    
# Script ausführen
main "$@"
