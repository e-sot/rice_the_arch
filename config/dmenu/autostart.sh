#!/bin/sh

# Définition de la disposition du clavier français
setxkbmap fr &

# Configuration de l'écran et de la résolution
xrandr --output Virtual-1 --mode 1920x1080 &

# Fond d'écran (nécessite feh)
feh --bg-scale /usr/share/backgrounds/default.jpg &

# Compositeur pour les effets visuels
picom -b &

# Gestionnaire de réseau
nm-applet &

# Contrôle du volume
volumeicon &

# Gestionnaire de batterie
cbatticon &

# Gestionnaire de presse-papiers
clipmenud &

# Gestionnaire de notifications
dunst &

# Économiseur d'écran
xscreensaver -no-splash &

# Support pour les polices
xset +fp /usr/share/fonts/local &
xset fp rehash &

# Réglage du taux de répétition du clavier
xset r rate 300 50 &

# Désactiver le bip système
xset -b &

# Démarrer le daemon pour les polices
xsettingsd &

# Statut de la barre DWM
while true; do
    xsetroot -name "$(date +"%F %R") | $(free -h | awk '/^Mem/ {print $3}') | $(acpi -b | cut -d' ' -f4) | $(hostname)"
    sleep 1s
done &

# Lancer les applications au démarrage
firefox &
terminal &
