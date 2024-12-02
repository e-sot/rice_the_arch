#!/usr/bin/env bash
set -eo pipefail

# Fonction de nettoyage système
cleanup_system() {
    echo ">>> Nettoyage du système en cours..."
    
    # Nettoyage pacman
    pacman -Scc --noconfirm
    pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
    rm -rf /var/cache/pacman/pkg/*
    
    # Nettoyage des journaux
    journalctl --vacuum-size=50M
    find /var/log -type f -name '*.old' -delete
    find /var/log -type f -name '*.gz' -delete
    truncate -s 0 /var/log/{wtmp,btmp,lastlog,messages,syslog}
    
    # Nettoyage des caches
    rm -rf /tmp/* /var/tmp/*
    rm -rf /root/.cache /home/*/.cache
    rm -rf /var/lib/systemd/coredump/*
    
    # Nettoyage des paquets orphelins
    pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
    
    
    sync
}

# Fonction de vérification et gestion de l'espace
check_disk_space() {
    local min_space=5000000  # 500MB minimum
    local available_space=$(df / | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$min_space" ]; then
        echo ">>> Espace disque insuffisant. Lancement du nettoyage..."
        cleanup_system
        
        # Revérification après nettoyage
        available_space=$(df / | awk 'NR==2 {print $4}')
        if [ "$available_space" -lt "$min_space" ]; then
            echo ">>> Nettoyage supplémentaire nécessaire..."
            
            # Nettoyage agressif
            rm -rf /usr/share/doc/*
            rm -rf /usr/share/man/*
            rm -rf /usr/share/locale/*
            
            # Compression des journaux restants
            find /var/log -type f -exec truncate -s 0 {} \;
            
            # Optimisation finale du disque
            dd if=/dev/zero of=/EMPTY bs=1M || true
            rm -f /EMPTY
            sync
        fi
    fi
    
    # Affichage de l'espace final
    df -h /
}

# Exécution principale
echo ">>> Début de la vérification d'espace..."
check_disk_space

# Nettoyage VirtualBox si nécessaire
if [[ -f /root/.vbox_version ]]; then
    echo ">>> Nettoyage VirtualBox..."
    rm -rf /root/.vbox_version
    rm -rf /root/.bash_history
    rm -rf /home/*/.bash_history
fi

# Compression finale si demandée
if [[ $WRITE_ZEROS == "true" ]]; then
    echo ">>> Optimisation finale du disque..."
    dd if=/dev/zero of=/zerofile bs=1M || true
    rm -f /zerofile
    sync
fi

echo ">>> Nettoyage terminé"
