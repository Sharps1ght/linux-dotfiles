#!/usr/bin/env bash
sudo pacman --needed -Syyu ark thunar btop chromium dnscrypt-proxy fastfetch fish fuse gtk2 gtk3 gtk4 imagemagick kitty mako man-db man-pages neovim noto-fonts noto-fonts-emoji nerd-fonts nvidia-open openvpn pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi swaybg vlc vlc-plugins-all wayland wireplumber wl-clipboard xdg-desktop-portal zerotier-one $dewm
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now dnscrypt-proxy.service
systemctl --user enable --now pipewire
systemctl --user enable --now wireplumber
cd ~/
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh
echo "If you want to reboot right now, press CTRL+C and use 'reboot'."
for i in {1..30}; do
  sleep 1
done
reboot
