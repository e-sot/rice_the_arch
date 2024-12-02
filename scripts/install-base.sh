#!/bin/bash

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly REQUIRED_SPACE=1
readonly MOUNT_POINT="/mnt"
readonly LOG_FILE="/var/log/${SCRIPT_NAME}.log"
readonly LOCK_FILE="/var/run/${SCRIPT_NAME}.lock"

# System Configuration
readonly DISK='/dev/sda'
readonly FQDN='vagrant-arch.vagrantup.com'
readonly KEYMAP='fr'
readonly LANGUAGE='fr_FR.UTF-8'
readonly TIMEZONE='Europe/Paris'
readonly CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
readonly BOOT_PARTITION="${DISK}1"
readonly SWAP_PARTITION="${DISK}2"
readonly ROOT_PARTITION="${DISK}3"
readonly TARGET_DIR='/mnt'
readonly COUNTRY=${COUNTRY:-FR}
readonly MIRRORLIST="https://archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
readonly SWAP_SIZE="2048"
readonly PASSWORD=$(/usr/bin/openssl rand -base64 16)

# Enhanced logging functions
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    printf "%s [%s] %s\n" "$timestamp" "$level" "$message" | tee -a "$LOG_FILE" >&2
}

log_info() { log "INFO" "$1"; }
log_error() { log "ERROR" "$1"; }
log_debug() { log "DEBUG" "$1"; }
log_warn() { log "WARN" "$1"; }

# Error handling with line numbers
error_handler() {
    local exit_code=$?
    local line_number=$1
    log_error "Erreur à la ligne ${line_number}. Code de sortie: ${exit_code}"
    cleanup
    exit $exit_code
}
trap 'error_handler ${LINENO}' ERR

# Enhanced cleanup function
cleanup() {
    log_info "Nettoyage en cours..."
    
    for mount_point in "${TARGET_DIR}/boot" "${TARGET_DIR}"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            umount -R "$mount_point" || log_warn "Impossible de démonter ${mount_point}"
        fi
    done
    
    if swapon --show | grep -q "${SWAP_PARTITION}"; then
        swapoff "${SWAP_PARTITION}" || log_warn "Impossible de désactiver le swap"
    fi
    
    rm -rf "${LOCK_FILE}"
}
trap cleanup EXIT

# Disk space verification
check_disk_space() {
    local path="$1"
    local required_space="${2:-$REQUIRED_SPACE}"
    
    local available_space
    available_space=$(df -BG "$path" 2>/dev/null | awk 'NR==2 {print $4}' | tr -dc '0-9')
    
    if [ "${available_space:-0}" -lt "$required_space" ]; then
        log_error "Espace insuffisant dans $path (${available_space}G disponible, ${required_space}G requis)"
        return 1
    fi
    return 0
}

# Network verification
verify_network() {
    local retries=3
    local wait=5
    
    for ((i=1; i<=retries; i++)); do
        if ping -c 1 archlinux.org >/dev/null 2>&1; then
            return 0
        fi
        log_warn "Tentative $i/$retries: Vérification de la connexion réseau"
        sleep "$wait"
    done
    
    log_error "Pas de connexion réseau après $retries tentatives"
    return 1
}

# Partition setup
setup_partitions() {
    log_info "Configuration des partitions..."
    
    # Destruction des signatures existantes
    wipefs --all --force ${DISK}
    
    log_info "Création des partitions..."
    sgdisk --zap-all ${DISK}
    sgdisk --new=1:0:+512M --typecode=1:ef00 ${DISK}
    sgdisk --new=2:0:+${SWAP_SIZE}M --typecode=2:8200 ${DISK}
    sgdisk --new=3:0:0 --typecode=3:8300 ${DISK}
    
    # Attendre que le noyau détecte les nouvelles partitions
    sleep 5
    
    log_info "Formatage des partitions..."
    mkfs.fat -F32 ${BOOT_PARTITION}
    mkswap ${SWAP_PARTITION}
    mkfs.ext4 -F ${ROOT_PARTITION}
    
    # Attendre que le formatage soit complètement terminé
    sleep 2
    
    log_info "Montage des partitions..."
    mount ${ROOT_PARTITION} ${TARGET_DIR}
    mkdir -p ${TARGET_DIR}/boot
    mount ${BOOT_PARTITION} ${TARGET_DIR}/boot
    swapon ${SWAP_PARTITION}
}


# System installation
install_base_system() {
    log_info "Configuration des miroirs..."
    curl -s "$MIRRORLIST" | sed 's/^#Server/Server/' | sort -R > /etc/pacman.d/mirrorlist
    
    log_info "Installation du système de base..."
    pacstrap ${TARGET_DIR} base base-devel linux linux-firmware
    
    log_info "Installation des paquets essentiels..."
    arch-chroot ${TARGET_DIR} pacman -S --noconfirm \
        gptfdisk openssh grub efibootmgr dhcpcd netctl vim git wget curl \
        virtualbox-guest-utils zram-generator irqbalance thermald
}

# System configuration
configure_system() {
    log_info "Configuration du système..."
    
    # Generate fstab
    genfstab -U ${TARGET_DIR} >> "${TARGET_DIR}/etc/fstab"
    
    # Create and execute configuration script
    cat > "${TARGET_DIR}${CONFIG_SCRIPT}" <<'EOF'
#!/usr/bin/env bash

# System configuration
echo "${FQDN}" > /etc/hostname
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Locale configuration
sed -i "s/#${LANGUAGE}/${LANGUAGE}/" /etc/locale.gen
locale-gen
echo "LANG=${LANGUAGE}" > /etc/locale.conf

# Network configuration
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable dhcpcd@eth0.service

# Additional services
systemctl enable sshd.service
systemctl enable irqbalance
systemctl enable thermald

# User configuration
useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
chmod 0440 /etc/sudoers.d/10_vagrant

# SSH configuration
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" > /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# System optimizations
cat > /etc/sysctl.d/99-sysctl.conf <<SYSCTL
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5
net.ipv4.tcp_fastopen=3
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
SYSCTL

# ZRAM configuration
cat > /etc/systemd/zram-generator.conf <<ZRAM
[zram0]
zram-size = ram/2
compression-algorithm = zstd
ZRAM

# Final cleanup
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*
rm -rf /var/log/*
EOF

    chmod +x "${TARGET_DIR}${CONFIG_SCRIPT}"
    arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
    rm "${TARGET_DIR}${CONFIG_SCRIPT}"
}

# Main execution
main() {
    if [ "$(id -u)" != "0" ]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    verify_network
    check_disk_space ${TARGET_DIR}
    setup_partitions
    install_base_system
    configure_system
    
    log_info "Installation terminée avec succès!"
}

main "$@"
