#!/usr/bin/env bash
cd ~/
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh
cd ~/
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd ~/ && rm -rfv yay/ cachyos-repo/ cachyos-repo.tar.xz
sleep 5
sudo pacman --needed --noconfirm -Syyu ark awww base-devel btop dnscrypt-proxy fastfetch fish fuse git gtk2 gtk3 gtk4 helium-browser-bin imagemagick kitty mako man-db man-pages neovim noto-fonts noto-fonts-emoji nerd-fonts linux-cachyos linux-cachyos-headers linux-cachyos-nvidia-open pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi mpv wayland wireplumber wl-clipboard xdg-desktop-portal zerotier-one niri xwayland-satellite xdg-desktop-portal-gnome
sudo systemctl enable --now NetworkManager.service
# sudo systemctl enable --now dnscrypt-proxy.service
systemctl --user enable --now pipewire
systemctl --user enable --now wireplumber
echo "If you want to reboot right now, press CTRL+C and use 'reboot' or wait 30 seconds for automatic reboot."
for i in {1..30}; do
  sleep 1
done
reboot
