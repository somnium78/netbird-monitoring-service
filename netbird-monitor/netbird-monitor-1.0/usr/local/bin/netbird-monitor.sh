#!/bin/bash
# /usr/local/bin/netbird-monitor.sh

LOGFILE="/var/log/netbird-monitor.log"
MIN_PEERS=3

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

check_netbird() {
    local status_output
    local connected_peers
    local total_peers

    # NetBird Status abrufen
    status_output=$(netbird status 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_message "ERROR: NetBird status command failed"
        return 1
    fi

    # Peers count extrahieren (Format: "5/8 Connected")
    peers_line=$(echo "$status_output" | grep "Peers count:")

    if [ -z "$peers_line" ]; then
        log_message "ERROR: Could not find peers count in status output"
        return 1
    fi

    # Zahlen extrahieren
    connected_peers=$(echo "$peers_line" | sed -n 's/.*Peers count: \([0-9]*\)\/\([0-9]*\) Connected.*/\1/p')
    total_peers=$(echo "$peers_line" | sed -n 's/.*Peers count: \([0-9]*\)\/\([0-9]*\) Connected.*/\2/p')

    if [ -z "$connected_peers" ] || [ -z "$total_peers" ]; then
        log_message "ERROR: Could not parse peer counts from: $peers_line"
        return 1
    fi

    log_message "INFO: Connected peers: $connected_peers/$total_peers"

    # Prüfen ob Neustart erforderlich
    if [ "$connected_peers" -lt "$MIN_PEERS" ]; then
        log_message "WARNING: Only $connected_peers peers connected (minimum: $MIN_PEERS). Restarting NetBird..."

        # NetBird neu starten
        netbird down
        sleep 2
        netbird up

        if [ $? -eq 0 ]; then
            log_message "INFO: NetBird successfully restarted"
        else
            log_message "ERROR: NetBird restart failed"
            return 1
        fi
    else
        log_message "INFO: NetBird status OK ($connected_peers/$total_peers peers)"
    fi

    return 0
}

# Hauptfunktion
main() {
    # Log-Datei erstellen falls nicht vorhanden
    touch "$LOGFILE"

    log_message "INFO: NetBird monitor started"
    check_netbird
    log_message "INFO: NetBird monitor finished"
}

main "$@"
