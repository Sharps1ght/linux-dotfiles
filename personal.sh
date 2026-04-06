#!/usr/bin/env bash
echo "Do you want to use Hyprland (1.), Niri (2.) or something else (Enter)?"
echo "NOTE: no choice will leave you with no Desktop Environment and/or Window Manager, you will have to install it all on your own."
read -r -p "Your choice is " choise
if [[ -z $choise ]]; then
	echo "Aight, will leave DE/WM up to you"
fi
case $choise in
	1)
		echo "Aight, I will install Hyprland stuff for you"
		$dewm = "hyprland hyprlang hyprpaper hyprcursor xdg-desktop-portal-hyprland"
		;;
	2)
		echo "Aight, I will install Niri stuff for you"
		$dewm = "niri xdg-desktop-portal-gnome"
		;;
esac
sudo pacman --needed -Syyu ark thunar btop chromium dnscrypt-proxy fastfetch fish fuse gtk2 gtk3 gtk4 imagemagick kitty mako man-db man-pages neovim noto-fonts noto-fonts-emoji nerd-fonts nvidia-open openvpn pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi swaybg vlc vlc-plugins-all wayland wireplumber wl-clipboard xdg-desktop-portal zerotier-one $dewm
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now dnscrypt-proxy.service
systemctl --user enable --now pipewire
systemctl --user enable --now wireplumber
cp -r .config/* ~/.config/
mkdir ~/osu/
ln -s ~/osu/ ~/.local/share/osu
curl -L -o ~/osu/osu.AppImage https://guthub.com/ppy/osu/releases/latest/download/osu.AppImage
echo "If you want to reboot right now, press CTRL+C and use 'reboot'."
for i in {1..30}; do
	sleep 1
done
reboot
