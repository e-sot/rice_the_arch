#!/usr/bin/env bash
set -eo pipefail

# Configuration
DEBUG=true
LOG_FILE="/var/log/disk_manager.log"
REQUIRED_SPACE_DOWNLOAD=5000000  # 5GB pour les téléchargements
REQUIRED_SPACE_INSTALL=10000000   # 10GB pour l'installation
MOUNT_POINTS=("/" "/home" "/var" "/tmp")
CLEANUP_THRESHOLD=85  # Pourcentage d'utilisation déclenchant le nettoyage
CRITICAL_THRESHOLD=95 # Pourcentage d'utilisation critique

# Fonction de logging améliorée
log_debug() {
    local message="${1:-}" 
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [[ "$DEBUG" == "true" ]]; then
        echo "[DEBUG] $timestamp: $message" | tee -a "$LOG_FILE"
    fi
}
# Fonction pour calculer le pourcentage d'utilisation
get_usage_percentage() {
    local mount_point=$1
    df -h "$mount_point" | awk 'NR==2 {print $5}' | tr -d '%'
}

# Fonction pour convertir KB en format lisible
human_readable() {
    local size=$1
    awk 'BEGIN {
        suffix[1] = "KB"; suffix[2] = "MB"; suffix[3] = "GB"; suffix[4] = "TB";
        for(i=1; size > 1024 && i < 4; i++) size = size/1024;
        printf("%.2f %s", size, suffix[i]);
    }'
}

# Fonction de nettoyage agressive
aggressive_cleanup() {
    local mount_point=$1
    log_debug "WARNING" "Lancement du nettoyage agressif sur $mount_point"
    
    # Liste des répertoires à nettoyer
    local cleanup_dirs=(
        "/var/cache/pacman/pkg/*"
        "/var/log/*"
        "/tmp/*"
        "/var/tmp/*"
        "/root/.cache/*"
        "/home/*/.cache/*"
        "/var/lib/systemd/coredump/*"
        "/var/lib/machines/*"
        "/var/lib/portables/*"
    )

    for dir in "${cleanup_dirs[@]}"; do
        if [ -d "$(dirname "$dir")" ]; then
            rm -rf $dir
            log_debug "INFO" "Nettoyage de $dir"
        fi
    done

    # Nettoyage système approfondi
    pacman -Scc --noconfirm
    pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
    journalctl --vacuum-size=50M
    find /var/log -type f -name "*.old" -delete
    find /var/log -type f -name "*.gz" -delete
    find /var/log -type f -exec truncate -s 0 {} \;
}

# Fonction pour trouver l'espace disponible sur tous les points de montage
find_available_space() {
    local mount_point=$1
    local available=$(df -k "$mount_point" | awk 'NR==2 {print $4}')
    local total=$(df -k "$mount_point" | awk 'NR==2 {print $2}')
    local usage=$(get_usage_percentage "$mount_point")
    
    log_debug "INFO" "Point de montage: $mount_point"
    log_debug "INFO" "Espace disponible: $(human_readable $available)"
    log_debug "INFO" "Espace total: $(human_readable $total)"
    log_debug "INFO" "Utilisation: $usage%"
    
    echo $available
}

# Fonction pour trouver le point de montage avec le plus d'espace
find_best_mount_point() {
    local max_space=0
    local best_mount=""
    
    for mount in "${MOUNT_POINTS[@]}"; do
        if [ -d "$mount" ]; then
            local space=$(find_available_space "$mount")
            log_debug "INFO" "Espace disponible sur $mount: $(human_readable $space)"
            if [ "$space" -gt "$max_space" ]; then
                max_space=$space
                best_mount=$mount
            fi
        fi
    done
    echo "$best_mount:$max_space"
}

# Fonction pour vérifier l'espace nécessaire pour une opération
check_space_for_operation() {
    local operation=$1
    local required_space=$2
    local current_dir=$3
    
    log_debug "INFO" "Vérification de l'espace pour $operation (requis: $(human_readable $required_space))"
    
    local usage=$(get_usage_percentage "$current_dir")
    if [ "$usage" -gt "$CRITICAL_THRESHOLD" ]; then
        log_debug "CRITICAL" "Utilisation critique détectée: $usage%"
        aggressive_cleanup "$current_dir"
    elif [ "$usage" -gt "$CLEANUP_THRESHOLD" ]; then
        log_debug "WARNING" "Utilisation élevée détectée: $usage%"
        source /scripts/cleanup.sh
    fi
    
    local available_space=$(find_available_space "$current_dir")
    if [ "$available_space" -lt "$required_space" ]; then
        log_debug "WARNING" "Espace insuffisant pour $operation"
        
        # Chercher un meilleur point de montage
        local best_mount_info=$(find_best_mount_point)
        local best_mount=$(echo "$best_mount_info" | cut -d':' -f1)
        local best_space=$(echo "$best_mount_info" | cut -d':' -f2)
        
        if [ -n "$best_mount" ] && [ "$best_space" -gt "$required_space" ]; then
            log_debug "INFO" "Point de montage alternatif trouvé: $best_mount avec $(human_readable $best_space)"
            echo "$best_mount"
            return 0
        else
            log_debug "WARNING" "Aucun point de montage approprié trouvé, lancement du nettoyage"
            aggressive_cleanup "$current_dir"
            
            # Revérifier après nettoyage
            available_space=$(find_available_space "$current_dir")
            if [ "$available_space" -lt "$required_space" ]; then
                log_debug "CRITICAL" "Espace toujours insuffisant après nettoyage"
                return 1
            fi
        fi
    fi
    
    echo "$current_dir"
    return 0
}

# Fonction de surveillance continue
monitor_space() {
    while true; do
        for mount_point in "${MOUNT_POINTS[@]}"; do
            local usage=$(get_usage_percentage "$mount_point")
            if [ "$usage" -gt "$CRITICAL_THRESHOLD" ]; then
                log_debug "CRITICAL" "Alerte espace disque sur $mount_point: $usage%"
                aggressive_cleanup "$mount_point"
            elif [ "$usage" -gt "$CLEANUP_THRESHOLD" ]; then
                log_debug "WARNING" "Utilisation élevée sur $mount_point: $usage%"
                source /scripts/cleanup.sh
            fi
        done
        sleep 300  # Vérification toutes les 5 minutes
    done
}

# Fonction principale
main() {
    local operation=$1
    local current_dir=$2
    
    case $operation in
        "download")
            required_space=$REQUIRED_SPACE_DOWNLOAD
            ;;
        "install")
            required_space=$REQUIRED_SPACE_INSTALL
            ;;
        "monitor")
            monitor_space
            ;;
        *)
            log_debug "ERROR" "Opération inconnue: $operation"
            return 1
            ;;
    esac
    
    if [ "$operation" != "monitor" ]; then
        local target_dir=$(check_space_for_operation "$operation" "$required_space" "$current_dir")
        local status=$?
        
        if [ $status -eq 0 ]; then
            echo "$target_dir"
        else
            log_debug "ERROR" "Échec de la vérification d'espace pour $operation"
            return 1
        fi
    fi
}

# Démarrage du monitoring en arrière-plan si demandé
if [[ "${1:-}" == "--monitor" ]]; then
    monitor_space &
fi

# Si exécuté directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
