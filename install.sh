#!/bin/bash

# ╔══════════════════════════════════════════════╗
# ║     Colony Desktop — Script d'installation    ║
# ║          Hyprland Rice by Lin & EVE 💜        ║
# ╚══════════════════════════════════════════════╝

set -e

# Couleurs
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${PURPLE}${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║       Colony Desktop Installer       ║"
echo "  ║            by Lin & EVE 💜           ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

# Vérification Arch Linux
if ! command -v pacman &> /dev/null; then
    echo "❌ Ce script est conçu pour Arch Linux (pacman requis)"
    exit 1
fi

# Vérification paru
if ! command -v paru &> /dev/null; then
    echo "⚠️  paru n'est pas installé. Installation..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru-install
    cd /tmp/paru-install && makepkg -si --noconfirm
    cd - && rm -rf /tmp/paru-install
    echo "✅ paru installé"
fi

echo -e "${PURPLE}[1/5]${NC} Installation des paquets officiels..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    hyprlock \
    hypridle \
    rofi-wayland \
    ghostty \
    nemo \
    waybar \
    swaync \
    cliphist \
    wl-clipboard \
    playerctl \
    imv \
    pavucontrol \
    blueman \
    nwg-look \
    papirus-icon-theme \
    ttf-jetbrains-mono-nerd \
    fastfetch \
    chafa \
    brightnessctl \
    wf-recorder \
    starship \
    zsh \
    grim \
    slurp \
    jq \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    pipewire \
    wireplumber

echo -e "${PURPLE}[2/5]${NC} Installation des paquets AUR..."
paru -S --needed --noconfirm \
    ags-hyprpanel-git \
    swww \
    hyprshot \
    hyprsunset \
    matugen-bin \
    bibata-cursor-theme

echo -e "${PURPLE}[3/5]${NC} Sauvegarde des anciennes configs..."
BACKUP_DIR="$HOME/.config/colony-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for dir in hypr ghostty rofi fastfetch; do
    if [ -d "$HOME/.config/$dir" ]; then
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/"
        echo "  📦 Sauvegardé: ~/.config/$dir → $BACKUP_DIR/$dir"
    fi
done

echo -e "${PURPLE}[4/5]${NC} Installation des configs Colony..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copier les configs
cp -r "$SCRIPT_DIR/config/hypr" "$HOME/.config/"
cp -r "$SCRIPT_DIR/config/ghostty" "$HOME/.config/"
cp -r "$SCRIPT_DIR/config/rofi" "$HOME/.config/"
cp -r "$SCRIPT_DIR/config/fastfetch" "$HOME/.config/"

# Créer le dossier wallpapers
mkdir -p "$HOME/Images/Wallpapers"

# Copier les wallpapers s'il y en a
if [ -d "$SCRIPT_DIR/assets/wallpapers" ] && [ "$(ls -A $SCRIPT_DIR/assets/wallpapers 2>/dev/null)" ]; then
    cp "$SCRIPT_DIR/assets/wallpapers/"* "$HOME/Images/Wallpapers/"
    echo "  🖼️  Wallpapers copiés dans ~/Images/Wallpapers/"
fi

echo -e "${PURPLE}[5/5]${NC} Configuration finale..."

# Ajouter fastfetch au .zshrc si absent
if ! grep -q "fastfetch" "$HOME/.zshrc" 2>/dev/null; then
    echo "fastfetch" >> "$HOME/.zshrc"
    echo "  ✅ Fastfetch ajouté au .zshrc"
fi

# Vérifier si swww ou awww est installé
if command -v awww &> /dev/null && ! command -v swww &> /dev/null; then
    echo "  ⚠️  'swww' installé sous le nom 'awww' — création des symlinks..."
    sudo ln -sf /usr/bin/awww /usr/bin/swww
    sudo ln -sf /usr/bin/awww-daemon /usr/bin/swww-daemon
fi

echo ""
echo -e "${PURPLE}${BOLD}  ✨ Colony Desktop installé avec succès ! ✨${NC}"
echo ""
echo "  Prochaines étapes :"
echo "  1. Déconnectez-vous et sélectionnez Hyprland comme session"
echo "  2. Ajoutez un wallpaper dans ~/Images/Wallpapers/"
echo "  3. Personnalisez HyprPanel via son interface (clic droit sur la barre)"
echo ""
echo "  Raccourcis principaux :"
echo "  ⊞ (Super)           → Lanceur d'apps (Rofi)"
echo "  ⊞ + Enter           → Terminal (Ghostty)"
echo "  ⊞ + E               → Fichiers (Nemo)"
echo "  ⊞ + B               → Firefox"
echo "  ⊞ + Q               → Fermer la fenêtre"
echo "  ⊞ + F               → Plein écran"
echo "  ⊞ + L               → Verrouiller"
echo "  ⊞ + 1-9             → Workspace 1-9"
echo "  Print                → Screenshot"
echo ""
echo -e "  ${PURPLE}💜 Colony Desktop — by Lin & EVE${NC}"
