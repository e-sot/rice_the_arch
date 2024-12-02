#!/usr/bin/bash -x

echo ">>>> install-rice.sh: Installing rice dependencies..."
pacman -S --noconfirm \
    python-pip \
    python-pywal \
    xorg-xrdb \
    xorg-xrandr \
    xwallpaper \
    picom \
    zsh \
    zsh-syntax-highlighting \
    zsh-autosuggestions \
    ttf-jetbrains-mono \
    ttf-font-awesome \
    xcompmgr

# Install AUR helper
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm

# Install AUR packages
paru -S --noconfirm \
    pywal-git \
    zsh-theme-powerlevel10k-git

# Configure ZSH
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Setup pywal
mkdir -p ~/.cache/wal
cp -r config/pywal/templates/* ~/.cache/wal/

# Configure X11
xrandr --output Virtual-1 --mode 1920x1080
xrdb -merge ~/.Xresources

# Start compositor
xcompmgr -c -f -n &

# Initial wallpaper and color scheme
wal -i ~/Pictures/wallpapers/default.jpg

# Enable services
systemctl --user enable picom.service

echo ">>>> install-rice.sh: Rice installation complete!"
