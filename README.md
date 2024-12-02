# 🍚 Rice - Automated Arch Linux Rice

A minimalist and automated Arch Linux customization project featuring DWM, ST terminal, and dynamic theming with Pywal. Built with Packer for easy VM deployment and testing.

## ⚙️ System Requirements

    VirtualBox
    Packer
    PowerShell (for Windows deployment)
    20GB free disk space
    4GB RAM minimum

## ✨ Features

- Automated Arch Linux installation and configuration
- DWM window manager with custom patches
- ST terminal with JetBrains Mono font
- Dynamic color schemes with Pywal integration
- VirtualBox support for testing
- Automated disk management and cleanup

## 🛠️ Components

- **Window Manager**: DWM with custom configuration
- **Terminal**: ST with JetBrains Mono font
- **Menu**: dmenu with Pywal integration
- **Compositor**: Picom with blur effects
- **Shell**: ZSH with custom aliases
- **Theme**: Dynamic colors using Pywal

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/rice

# Launch the build
packer build arch-template.json

```

## 🎨 Customization
The rice can be customized by:

    Adding wallpapers to /assets/wallpapers
    Modifying config files in /config
    Adjusting installation scripts in /scripts
