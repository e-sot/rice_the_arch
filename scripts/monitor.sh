#!/usr/bin/env bash
set -eo pipefail

# Configuration
MONITOR_LOG="/var/log/monitor.log"
DISK_CHECK_INTERVAL=5
PROCESS_CHECK_INTERVAL=2
PID_FILE="/tmp/monitor.pid"

# Créer le fichier PID
echo $$ > "$PID_FILE"

# Fonction de nettoyage
cleanup() {
    rm -f "$PID_FILE"
    exit 0
}
trap cleanup EXIT

# Fonction de monitoring disque
monitor_disk() {
    while true; do
        for mount_point in "/" "/tmp" "/var"; do
            usage=$(df -h "$mount_point" | awk 'NR==2 {print $5}' | tr -d '%')
            if [ "$usage" -gt 80 ]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERTE: $mount_point utilisation: $usage%" >> "$MONITOR_LOG"
                /scripts/cleanup.sh
            fi
        done
        sleep "$DISK_CHECK_INTERVAL"
    done
}

# Fonction de monitoring processus
monitor_processes() {
    while true; do
        ps aux | grep -E 'install-.*\.sh' | grep -v grep | while read -r process; do
            pid=$(echo "$process" | awk '{print $2}')
            name=$(echo "$process" | awk '{print $11}')
            mem=$(echo "$process" | awk '{print $4}')
            cpu=$(echo "$process" | awk '{print $3}')
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Process: $name (PID: $pid) MEM: $mem% CPU: $cpu%" >> "$MONITOR_LOG"
        done
        sleep "$PROCESS_CHECK_INTERVAL"
    done
}

# Lancement des moniteurs en parallèle
monitor_disk &
monitor_processes &

# Attendre que les processus enfants se terminent
wait
