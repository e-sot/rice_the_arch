#!/usr/bin/bash -x

# Arrêt sur erreur
set -euo pipefail

# Variables globales
export USER_HOME="/home/${SUDO_USER:-$USER}"
export CONFIG_DIR="/etc/rice-config"
export CACHE_DIR="$USER_HOME/.cache"
export WAL_CACHE="$CACHE_DIR/wal"
export INSTALL_DIR="/usr/local/src"

# Fonction de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Gestion d'erreurs
handle_error() {
    log "Error on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Vérification des prérequis
check_prerequisites() {
    log "Checking prerequisites..."
    local deps=(git base-devel libxft libxinerama python-pip xorg-server xorg-xinit)
    
    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" >/dev/null 2>&1; then
            log "Installing $dep..."
            pacman -S --noconfirm "$dep"
        fi
    done
}

# Préparation des répertoires
setup_directories() {
    log "Setting up directories..."
    mkdir -p "$WAL_CACHE" "$CONFIG_DIR"
    
    # Copie des configurations
    cp -r config/* "$CONFIG_DIR/"
    chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR"
}

# Installation de pywal et génération des templates
setup_pywal() {
    log "Setting up pywal..."
    pip install pywal

    # Copie et préparation des templates
    cp "$CONFIG_DIR/pywal/templates/"* "$WAL_CACHE/"
    
    # Génération des chemins corrects dans les templates
    sed -i "s|/home/vagrant|$USER_HOME|g" "$WAL_CACHE/"*
    
    # Génération initiale des couleurs
    sudo -u "$SUDO_USER" wal -i "$CONFIG_DIR/assets/wallpapers/default.jpg" --saturate 0.6
}

# Compilation et installation des applications suckless
install_suckless() {
    log "Installing suckless applications..."
    local apps=(dwm st dmenu)
    
    for app in "${apps[@]}"; do
        cd "$INSTALL_DIR/$app"
        
        # Backup du config.h original
        [ -f config.h ] && mv config.h config.h.orig
        
        # Copie de notre config.h avec les bons chemins
        sed "s|/home/vagrant|$USER_HOME|g" "$CONFIG_DIR/$app/config.h" > config.h
        
        # Compilation et installation
        make clean install
    done
}

# Configuration du système
setup_system() {
    log "Configuring system..."
    
    # Configuration de X11
    cp "$CONFIG_DIR/x11/.xinitrc" "$USER_HOME/"
    cp "$CONFIG_DIR/x11/.Xresources" "$USER_HOME/"
    chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.xinitrc" "$USER_HOME/.Xresources"
    
    # Configuration de zsh
    cp "$CONFIG_DIR/zsh/.zshrc" "$USER_HOME/"
    cp "$CONFIG_DIR/zsh/aliases.zsh" "$USER_HOME/.oh-my-zsh/custom/"
    chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.zshrc" "$USER_HOME/.oh-my-zsh"
}

# Séquence principale d'installation
main() {
    log "Starting installation..."
    
    check_prerequisites
    setup_directories
    setup_pywal
    install_suckless
    setup_system
    
    log "Installation completed successfully!"
}

main "$@"
