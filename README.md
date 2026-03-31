# Colony Desktop 💜

> A modern, dark purple Hyprland rice for Arch Linux.
> Handcrafted by **Lin** & **EVE**.

<!-- TODO: ajouter screenshot ici -->
<!-- ![Colony Desktop](assets/preview.png) -->

---

## ✨ Features

- 🖥️ **Hyprland** — Dynamic tiling Wayland compositor
- 📊 **HyprPanel** — Modern AGS-based panel with dashboard & context menus
- 🚀 **Rofi** — App launcher with custom Colony theme
- 💻 **Ghostty** — GPU-accelerated terminal with transparency & blur
- 🖼️ **Swww** — Animated wallpaper daemon
- 🎨 **Matugen** — Material You color generation from wallpapers
- 🔒 **Hyprlock + Hypridle** — Lock screen & idle management
- 🌙 **Hyprsunset** — Blue light filter
- 📸 **Hyprshot** — Screenshot utility
- 🔔 **SwayNC** — Notification center
- 📋 **Cliphist** — Clipboard history
- 🎵 **Playerctl** — Media controls
- 📁 **Nemo** — File manager with integrated terminal
- 💎 **Fastfetch** — System fetch with custom ASCII art
- 🖱️ **Bibata** — Modern cursor theme
- 🔤 **JetBrainsMono Nerd Font** — Everywhere

## 🎨 Color Palette

| Element       | Color                                                        |
| ------------- | ------------------------------------------------------------ |
| Accent        | ![#9b59b6](https://placehold.co/15x15/9b59b6/9b59b6.png) `#9b59b6` |
| Accent Alt    | ![#8e44ad](https://placehold.co/15x15/8e44ad/8e44ad.png) `#8e44ad` |
| Background    | ![#0d0d14](https://placehold.co/15x15/0d0d14/0d0d14.png) `#0d0d14` |
| Foreground    | ![#cdd6f4](https://placehold.co/15x15/cdd6f4/cdd6f4.png) `#cdd6f4` |
| Inactive      | ![#2c2c2c](https://placehold.co/15x15/2c2c2c/2c2c2c.png) `#2c2c2c` |

## 📦 Dependencies

### Official repos (pacman)

```
hyprland hyprlock hypridle rofi-wayland ghostty nemo waybar swaync
cliphist wl-clipboard playerctl imv pavucontrol blueman nwg-look
papirus-icon-theme ttf-jetbrains-mono-nerd fastfetch chafa brightnessctl
wf-recorder starship zsh grim slurp jq pipewire wireplumber
xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

### AUR (paru)

```
ags-hyprpanel-git swww hyprshot hyprsunset matugen-bin bibata-cursor-theme
```

## 🚀 Installation

### Automatic (recommended)

```bash
git clone https://github.com/Project-Colony/hyprland-colony.git
cd hyprland-colony
chmod +x install.sh
./install.sh
```

The install script will:
1. Install all dependencies via pacman & paru
2. Back up your existing configs
3. Copy Colony configs to `~/.config/`
4. Set up fastfetch in your `.zshrc`
5. Create symlinks if needed (awww → swww)

### Manual

<details>
<summary>Click to expand manual installation steps</summary>

#### 1. Install paru (AUR helper)

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si
```

#### 2. Install dependencies

```bash
# Official repos
sudo pacman -S --needed hyprland hyprlock hypridle rofi-wayland ghostty \
    nemo waybar swaync cliphist wl-clipboard playerctl imv pavucontrol \
    blueman nwg-look papirus-icon-theme ttf-jetbrains-mono-nerd fastfetch \
    chafa brightnessctl wf-recorder starship zsh grim slurp jq pipewire \
    wireplumber xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# AUR
paru -S --needed ags-hyprpanel-git swww hyprshot hyprsunset matugen-bin \
    bibata-cursor-theme
```

#### 3. Clone and copy configs

```bash
git clone https://github.com/Project-Colony/hyprland-colony.git
cd hyprland-colony

# Backup existing configs
mkdir -p ~/.config/colony-backup
cp -r ~/.config/hypr ~/.config/colony-backup/ 2>/dev/null
cp -r ~/.config/ghostty ~/.config/colony-backup/ 2>/dev/null
cp -r ~/.config/rofi ~/.config/colony-backup/ 2>/dev/null
cp -r ~/.config/fastfetch ~/.config/colony-backup/ 2>/dev/null

# Copy Colony configs
cp -r config/hypr ~/.config/
cp -r config/ghostty ~/.config/
cp -r config/rofi ~/.config/
cp -r config/fastfetch ~/.config/
```

#### 4. Set up fastfetch on terminal launch

```bash
echo "fastfetch" >> ~/.zshrc
```

#### 5. Create wallpaper directory

```bash
mkdir -p ~/Images/Wallpapers
```

#### 6. Log out and select Hyprland

Log out of your current session and select **Hyprland** from your display manager.

</details>

## ⌨️ Keybindings

| Keybind                | Action                     |
| ---------------------- | -------------------------- |
| `Super` (tap)          | App launcher (Rofi)        |
| `Super + Enter`        | Terminal (Ghostty)         |
| `Super + E`            | File manager (Nemo)        |
| `Super + B`            | Browser (Firefox)          |
| `Super + Q`            | Close window               |
| `Super + F`            | Fullscreen                 |
| `Super + V`            | Toggle floating             |
| `Super + L`            | Lock screen                |
| `Super + N`            | Toggle blue light filter   |
| `Super + S`            | Toggle scratchpad          |
| `Super + 1-9`          | Switch workspace           |
| `Super + Shift + 1-9`  | Move window to workspace   |
| `Super + Arrow keys`   | Move focus                 |
| `Super + Mouse drag`   | Move/resize window         |
| `Print`                | Screenshot (full screen)   |
| `Super + Print`        | Screenshot (window)        |
| `Super + Shift + Print` | Screenshot (region)       |

## 📁 Structure

```
hyprland-colony/
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf       # Main config (sources all others)
│   │   ├── monitors.conf       # Monitor setup
│   │   ├── autostart.conf      # Autostart apps
│   │   ├── environment.conf    # Environment variables
│   │   ├── look.conf           # Appearance, colors, blur
│   │   ├── animations.conf     # Animation curves & config
│   │   ├── input.conf          # Keyboard & mouse
│   │   ├── keybinds.conf       # All keybindings
│   │   └── rules.conf          # Window rules
│   ├── ghostty/
│   │   └── config.ghostty      # Terminal config
│   ├── rofi/
│   │   ├── config.rasi         # Rofi config
│   │   └── colony.rasi         # Colony theme
│   └── fastfetch/
│       ├── config.jsonc        # Fastfetch config
│       └── eve-ascii.txt       # ASCII art logo
├── assets/
│   └── wallpapers/             # Wallpaper collection
├── scripts/                    # Utility scripts
├── install.sh                  # Automatic installer
└── README.md
```

## 🔧 Customization

### Monitors

Edit `config/hypr/monitors.conf` to match your setup:

```conf
monitor = HDMI-1, 2560x1440@144, 0x0, 1        # Primary (left)
monitor = HDMI-2, 1920x1080@60, 2560x0, 1       # Secondary (right)
monitor = DP-1, disable                           # Disabled
```

### Colors

All colors are centralized as variables in `config/hypr/look.conf`:

```conf
$accentColor = rgba(9b59b6ee)        # Change this to your color
$accentColorAlt = rgba(8e44adee)
$inactiveColor = rgba(2c2c2caa)
$shadowColor = rgba(1a1a2eee)
$bgColor = rgba(0d0d14ff)
```

### Keyboard layout

Edit `config/hypr/input.conf`:

```conf
kb_layout = fr          # Change to your layout (us, de, etc.)
```

### Wallpaper

Place wallpapers in `~/Images/Wallpapers/` and set one with:

```bash
swww img ~/Images/Wallpapers/your-wallpaper.png --transition-type grow
```

## 🙏 Credits & Inspiration

- [Hyprland](https://hyprland.org) — The compositor
- [HyprPanel](https://hyprpanel.com) — Panel/bar
- [Caelestia](https://github.com/caelestia-dots) — Animation curves & structure inspiration
- [Catppuccin](https://github.com/catppuccin) — Color palette inspiration
- [r/unixporn](https://reddit.com/r/unixporn) — Endless inspiration

## 📜 License

MIT — Do whatever you want with it.

---

*Made with 💜 by Lin & EVE*
