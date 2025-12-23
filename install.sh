#!/bin/bash
# Hyprland Dotfiles Installation Script

set -e

echo "=== Hyprland Dotfiles Installer ==="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running on Arch
if ! command -v pacman &> /dev/null; then
    echo "Error: This script is for Arch Linux only"
    exit 1
fi

# Check if paru is installed
if ! command -v paru &> /dev/null; then
    echo "Error: paru not found. Please install paru first."
    exit 1
fi

echo -e "${BLUE}Step 1: Installing packages...${NC}"
paru -S --needed - < packages.txt

echo ""
echo -e "${BLUE}Step 2: Creating config directories...${NC}"
mkdir -p ~/.config/{hypr,waybar,mako,alacritty,xdg-desktop-portal}

echo ""
echo -e "${BLUE}Step 3: Copying configuration files...${NC}"
cp -r hypr/* ~/.config/hypr/
cp -r waybar/* ~/.config/waybar/
cp -r mako/* ~/.config/mako/
cp -r alacritty/* ~/.config/alacritty/
cp -r xdg-desktop-portal/* ~/.config/xdg-desktop-portal/

# Make waybar scripts executable
chmod +x ~/.config/waybar/scripts/*.sh 2>/dev/null || true

echo ""
echo -e "${BLUE}Step 4: Installing SDDM configs (requires sudo)...${NC}"
sudo mkdir -p /etc/sddm.conf.d
sudo cp sddm/*.conf /etc/sddm.conf.d/ 2>/dev/null || echo "No SDDM conf files found"
sudo cp sddm/Xsetup /usr/share/sddm/scripts/Xsetup 2>/dev/null || echo "No Xsetup script found"
sudo chmod +x /usr/share/sddm/scripts/Xsetup 2>/dev/null || true

echo ""
echo -e "${BLUE}Step 5: Setting up Vim with plugins...${NC}"
# Install vim-plug if not already installed
if [ ! -f ~/.vim/autoload/plug.vim ]; then
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Copy vimrc
cp vim/vimrc ~/.vimrc

# Install vim plugins
echo "Installing Vim plugins (this may take a moment)..."
vim +PlugInstall +qall || echo "Vim plugins will install on first vim launch"

echo ""
echo -e "${BLUE}Step 6: Setting up custom PS1 (bash prompt)...${NC}"
# Copy custom PS1 to system profile.d
sudo cp ps1/custom_ps1.sh /etc/profile.d/custom_ps1.sh
sudo chmod +x /etc/profile.d/custom_ps1.sh

# Add sourcing to .bashrc if not already there
if ! grep -q "custom_ps1.sh" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Custom PS1 prompt" >> ~/.bashrc
    echo "if [ -f /etc/profile.d/custom_ps1.sh ]; then" >> ~/.bashrc
    echo "   . /etc/profile.d/custom_ps1.sh" >> ~/.bashrc
    echo "fi" >> ~/.bashrc
    echo "Added custom PS1 to .bashrc"
fi

echo ""
echo -e "${BLUE}Step 7: Enabling services...${NC}"
sudo systemctl enable sddm.service

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "To finish setup:"
echo "1. Reboot your system (or log out and back in for PS1)"
echo "2. Select 'Hyprland' from SDDM login screen"
echo "3. Press Super+Return to open terminal"
echo "4. Enjoy your setup!"
echo ""
echo "What's installed:"
echo "  ✓ Hyprland with Waybar, Mako, Hyprlock"
echo "  ✓ Alacritty terminal with Tokyo Night theme"
echo "  ✓ Vim with NERDTree, coc.nvim, and colorschemes"
echo "  ✓ Custom colorful bash prompt with git branch"
echo "  ✓ PipeWire audio with multi-device support"
echo ""
echo "Keybindings:"
echo "  Super+Return    - Terminal"
echo "  Super+D         - App launcher (rofi)"
echo "  Super+L         - Lock screen"
echo "  Super+Shift+Q   - Close window"
echo "  Super+Shift+E   - Exit Hyprland"
