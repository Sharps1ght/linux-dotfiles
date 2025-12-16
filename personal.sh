#!/usr/bin/env bash
sudo pacman --needed --noconfirm -Syyu ark thunar btop chromium dnscrypt-proxy fastfetch fish gtk2 gtk3 gtk4 hyprland hyprlang hyprpicker hyprpolkitagent hyprshot hyprutils imagemagick kitty mako man-db man-pages neovim noto-fonts noto-fonts-emoji nerd-fonts nvidia-open openvpn pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi swaybg vlc vlc-plugins-all wayland wireplumber wl-clipboard xdg-desktop-portal xdg-desktop-portal-hyprland zerotier-one
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now dnscrypt-proxy.service
systemctl --user enable --now pipewire
systemctl --user enable --now wireplumber
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
sudo nvim /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo nvim /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
echo "If you want to reboot right now, press CTRL+C and use 'reboot'."
for i in {1..30}; do
	sleep 1
done
reboot
