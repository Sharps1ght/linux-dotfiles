#!/usr/bin/env bash
echo "I AM NOT RESPONSIBLE FOR YOU NOT LIKING"
echo "WHATEVER I WANT TO USE/LIKE"
echo "PRESS CTRL+C TO ABORT"
echo "YOU HAVE 5..."
sleep 1
echo "YOU HAVE 4..."
sleep 1
echo "YOU HAVE 3..."
sleep 1
echo "YOU HAVE 2..."
sleep 1
echo "YOU HAVE 1..."
sleep 1
echo "YOU called it upon yourself."
sleep 3
echo "Applying configs..."
sleep 1
cd && cp -rf $HOME/linux-dotfiles/* $HOME/.config
echo "Updating database and installing the essentials..."
sleep 1
sudo pacman --needed --noconfirm -Syyu ark thunar btop chromium fastfetch fish gtk2 gtk3 gtk4 hyprland hyprcursor hypridle hyprlang hyprlock hyprpaper hyprpicker hyprpolkitagent hyprshot hyprutils imagemagick kitty mako man-db man-pages neovim noto-fonts noto-fonts-emoji nerd-fonts nvidia-open nvidia-utils openvpn pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi vlc vlc-plugins-all wayland waybar wireplumber wl-clipboard xdg-desktop-portal xdg-desktop-portal-hyprland zerotier-one
sleep 1
echo "Changing default shell to fish (cuz I personally prefer it)..."
sleep 1
chsh -s /usr/bin/fish $USER
sleep 1
echo "JUST IN CASE adding Hyprland to bash startup..."
echo "exec hyprland" >> /home/$USER/.bash_profile
sleep 1
echo "Installing yay..."
sleep 1
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg --noconfirm -si
cd .. && rm -rf yay
sleep 1
echo "Everything is done, doing hard reboot in 30 seconds."
echo "If you don't want to reboot for some reason, press CTRL+C."
echo "If you want to reboot right now, press CTRL+C and use 'reboot'."
sleep 30
reboot
