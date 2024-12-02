#!/usr/bin/bash -x

echo ">>>> install-fonts.sh: Installing fonts.."
pacman -S --noconfirm \
    ttf-jetbrains-mono \
    ttf-font-awesome \
    ttf-dejavu \
    ttf-liberation \
    noto-fonts \
    noto-fonts-emoji \
    ttf-hack \
    ttf-fira-code

echo ">>>> install-fonts.sh: Installing AUR fonts.."
paru -S --noconfirm \
    nerd-fonts-complete \
    ttf-ms-fonts

echo ">>>> install-fonts.sh: Setting up font configuration.."
mkdir -p ~/.config/fontconfig/conf.d/

cat > ~/.config/fontconfig/conf.d/10-sub-pixel-rgb.conf << EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <match target="font">
        <edit name="rgba" mode="assign"><const>rgb</const></edit>
        <edit name="hinting" mode="assign"><bool>true</bool></edit>
        <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
        <edit name="antialias" mode="assign"><bool>true</bool></edit>
        <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
    </match>
</fontconfig>
EOF

fc-cache -fv
