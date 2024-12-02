#!/bin/bash

# Set wallpaper and generate color scheme
wal -i "$(find $HOME/assets/wallpapers -type f | shuf -n 1)" &

# Start compositor
picom --config $HOME/.config/picom/picom.conf &

# Set keyboard layout
setxkbmap us &

# Start status bar
while true; do
    xsetroot -name "$(date +"%F %R") | $(free -h | awk '/^Mem/ {print $3}') | $(acpi -b | cut -d" " -f4)"
    sleep 1s
done &
