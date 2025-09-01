#!/bin/bash

set -euo pipefail

# Konfiguration
NETBIRD_BIN="/usr/bin/netbird"
MIN_PEERS=${MIN_PEERS:-3}
LOG_FILE="/var/log/netbird-monitor.log"
STATUS_TIMEOUT=10
DEBUG=${DEBUG:-false}

# Logging-Funktion
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # DEBUG nur wenn aktiviert
    if [[ "$level" == "DEBUG" && "$DEBUG" != "true" ]]; then
        return
    fi

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
        local peer_line=$(echo "$status_output" | grep "Peers count:" | head -1)
        if [[ $peer_line =~ ([0-9]+)/([0-9]+) ]]; then
            connected_peers=${BASH_REMATCH[1]}
            total_peers=${BASH_REMATCH[2]}
        fi
    elif echo "$status_output" | grep -q "Connected peers:"; then
        local peer_line=$(echo "$status_output" | grep "Connected peers:" | head -1)
        if [[ $peer_line =~ ([0-9]+)/([0-9]+) ]]; then
            connected_peers=${BASH_REMATCH[1]}
            total_peers=${BASH_REMATCH[2]}
        fi
    elif echo "$status_output" | grep -qE "[0-9]+/[0-9]+"; then
        local numbers=$(echo "$status_output" | grep -oE "[0-9]+/[0-9]+" | head -1)
        if [[ $numbers =~ ([0-9]+)/([0-9]+) ]]; then
            connected_peers=${BASH_REMATCH[1]}
            total_peers=${BASH_REMATCH[2]}
        fi
    fi

    if [[ $connected_peers -eq 0 && $total_peers -eq 0 ]]; then
        return 1
    fi

    echo "$connected_peers/$total_peers"
    return 0
}

# NetBird reconnect (down + up)
netbird_reconnect() {
    log "WARNING" "Reconnecting NetBird..."

    # Erst down (Output unterdrücken außer bei Fehlern)
    if ! "$NETBIRD_BIN" down >/dev/null 2>&1; then
        log "WARNING" "NetBird down failed, continuing with up..."
    fi

    # Dann up (Output unterdrücken außer bei Fehlern)
    if "$NETBIRD_BIN" up >/dev/null 2>&1; then
        log "INFO" "NetBird reconnected successfully"
        return 0
    else
        log "ERROR" "NetBird reconnect failed"
        return 1
    fi
}

# Hauptfunktion
main() {
    # Prüfen ob NetBird-Service enabled ist
    if ! is_netbird_enabled; then
        log "DEBUG" "NetBird service is disabled - monitoring skipped"
        exit 0
    fi

    # NetBird-Status abrufen
    local status_output
    if ! status_output=$(get_netbird_status); then
        log "WARNING" "Cannot get NetBird status - attempting reconnect"

        if netbird_reconnect; then
            log "DEBUG" "NetBird reconnect completed"
        fi

        exit 0
    fi

    # Peer-Count extrahieren
    local peer_info
    if ! peer_info=$(parse_peer_count "$status_output"); then
        log "ERROR" "Could not parse peer count from status output"
        log "DEBUG" "Status output was: $status_output"

        if netbird_reconnect; then
            log "DEBUG" "NetBird reconnect completed due to parsing error"
        fi

        exit 0
    fi

    # Peer-Zahlen aufteilen
    local connected_peers total_peers
    IFS='/' read -r connected_peers total_peers <<< "$peer_info"

    # Immer loggen: Peer-Status
    log "INFO" "Connected peers: $connected_peers/$total_peers"

    # Peer-Count prüfen
    if [[ $connected_peers -lt $MIN_PEERS ]]; then
        log "WARNING" "Only $connected_peers peers connected (minimum: $MIN_PEERS) - reconnecting"

        if netbird_reconnect; then
            log "DEBUG" "NetBird reconnect completed successfully"
        fi
    fi
}

# Script ausführen
main "$@"
