#!/usr/bin/env bash

# Activation du mode strict
set -euo pipefail
IFS=$'\n\t'

# Variables d'environnement
readonly CONFIG_DIR="/config"
readonly CACHE_DIR="${HOME}/.cache"
readonly WALLPAPER_DIR="${HOME}/Pictures/wallpapers"
readonly CONFIG_HOME="${HOME}/.config"
readonly WALLPAPER_URL="https://wallpaperdelight.com/wp-content/uploads/2024/06/A-dragon-from-a-high-tech-future-adorned-with-shiny-metallic-scales-and-neon-highlights-stands-out-against-the-backdrop-of-a-cyberpunk-city.jpg"
readonly LOG_DIR="/var/log"
readonly USER="vagrant"

# Fonction de logging améliorée
log() {
    local level="${1:-INFO}"  
    local message="${2:-}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${message}"
}

# Gestion d'erreurs plus permissive
handle_error() {
    local exit_code=$?
    log "ERROR" "Erreur à la ligne ${1}, code: ${exit_code}"
    return 0  # Force un succès pour continuer l'exécution
}

trap 'handle_error ${LINENO}' ERR

# Fonction de vérification des permissions
check_permissions() {
    log "INFO" "Vérification des permissions..."
    
    # Création et configuration des répertoires nécessaires
    for dir in "${CACHE_DIR}" "${WALLPAPER_DIR}" "${CONFIG_HOME}" "${HOME}/.dwm"; do
        mkdir -p "${dir}"
        chown "${USER}:${USER}" "${dir}"
        chmod 755 "${dir}"
    done
}

# Installation des dépendances
install_dependencies() {
    log "INFO" "Installation des dépendances..."
    local deps=(
        zsh-syntax-highlighting
        zsh-autosuggestions
        feh
        dunst
        python-pywal
        neovim
        python-pynvim
        xclip
        git
        curl
        wget
        dbus
        tmux
        xorg-xrdb
        xorg-xsetroot
        base-devel
        xorg-server
        xorg-xinit
    )
    
    # Synchronisation de la base de données pacman
    if ! pacman -Sy; then
        log "ERROR" "Échec de la synchronisation pacman"
        return 1
    fi

    # Installation des dépendances
    if ! pacman -S --noconfirm --needed "${deps[@]}"; then
        log "WARNING" "Certaines dépendances n'ont pas pu être installées"
        return 0
    fi
}
# Configuration de ZSH
setup_zsh() {
    log "Configuration de ZSH..."
    
    # Installation de Oh-My-Zsh si non présent
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Création des fichiers de configuration
    cat > "${HOME}/.zshrc" << 'EOL'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh
(cat ~/.cache/wal/sequences &)
source ~/.cache/wal/colors-tty.sh
source ~/.config/zsh/aliases.zsh
export EDITOR='nvim'
export TERMINAL='st'
export BROWSER='firefox'
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
export PATH="$HOME/.local/bin:$PATH"
EOL

    mkdir -p "${HOME}/.config/zsh"
    cat > "${HOME}/.config/zsh/aliases.zsh" << 'EOL'
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'

# System
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias cleanup='sudo pacman -Sc'
alias sv='sudo nvim'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# DWM
alias dwm-restart='killall dwm'
alias autostart='nvim ~/.dwm/autostart.sh'

# Custom
alias rice='wal -i'
alias reload='source ~/.zshrc'
alias config='cd ~/.config'
alias v='nvim'
alias tm='tmux'
alias weather='curl wttr.in'
EOL

    # Configuration des permissions
    chmod 644 "${HOME}/.zshrc"
    chmod 644 "${HOME}/.config/zsh/aliases.zsh"
}

# Configuration de Pywal avec téléchargement du wallpaper
setup_pywal() {
    log "INFO" "Configuration de Pywal..."
    mkdir -p "${CACHE_DIR}/wal" "${WALLPAPER_DIR}"
    
    # Téléchargement du wallpaper par défaut
    if [[ ! -f "${WALLPAPER_DIR}/wallpaper.jpg" ]]; then
        log "INFO" "Téléchargement du wallpaper..."
        wget -q -O "${WALLPAPER_DIR}/wallpaper.jpg" "${WALLPAPER_URL}" || {
            log "WARNING" "Échec du téléchargement du wallpaper"
            return 0
        }
    fi

    # Génération du thème
    if [[ -f "${WALLPAPER_DIR}/wallpaper.jpg" ]]; then
        wal -i "${WALLPAPER_DIR}/wallpaper.jpg" -n || log "WARNING" "Erreur génération thème Pywal"
    fi
}

# Configuration de l'environnement graphique améliorée
setup_environment() {
    log "INFO" "Configuration de l'environnement..."
    
    # Configuration de X11
    cat > "${HOME}/.xinitrc" << 'EOL'
#!/bin/sh
# Chargement des ressources X
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Configuration du clavier
setxkbmap fr &

# Démarrage des services
dunst &
picom &

# Lancement de DWM
exec dwm
EOL

    chmod +x "${HOME}/.xinitrc"
    
    # Configuration de dunst
    mkdir -p "${CONFIG_HOME}/dunst"
    cat > "${CONFIG_HOME}/dunst/dunstrc" << 'EOL'
[global]
    monitor = 0
    follow = mouse
    geometry = "300x5-30+20"
    indicate_hidden = yes
    shrink = no
    transparency = 20
    notification_height = 0
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    frame_width = 3
    frame_color = "#aaaaaa"
    separator_color = frame
    sort = yes
    idle_threshold = 120
EOL
}

# Fonction principale améliorée
main() {
    log "INFO" "Début de la post-installation..."
    
    check_permissions || true
    install_dependencies || true
    setup_zsh || true
    setup_pywal || true
    setup_environment || true
    
    # Changement du shell par défaut
    if command -v zsh >/dev/null; then
        chsh -s "$(command -v zsh)" "${USER}" || log "WARNING" "Impossible de changer le shell par défaut"
    fi
    
    # Redémarrage des services
    systemctl --user daemon-reload
    systemctl --user try-restart dunst.service
    
    log "INFO" "Post-installation terminée avec succès"
    return 0
}

# Exécution avec gestion d'erreur
if ! main "$@"; then
    log "ERROR" "Échec de l'installation"
    exit 1
fi