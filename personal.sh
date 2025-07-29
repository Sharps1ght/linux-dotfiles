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
cd $HOME && cp -rf $HOME/linux-dotfiles/* $HOME/.config
echo "Updating package databases and upgrading installed packages..."
sleep 1
sudo pacman --noconfirm -Syyu
echo "Installing the essentials..."
sleep 1
sudo pacman --needed --noconfirm -S ark thunar base-devel btop fastfetch gtk2 gtk3 gtk4 hyprland hyprcursor hypridle hyprlang hyprpaper hyprpicker hyprpolkitagent hyprshot hyprutils imagemagick jre8-openjdk jdk-openjdk kitty neovim networkmanager noto-fonts ntfs-3g nerd-fonts nvidia nvidia-utils openvpn pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi-wayland sudo swaync telegram-desktop uwsm vlc wayland wireplumber wl-clipboard xdg-desktop-portal xdg-desktop-portal-hyprland zerotier-one noto-fonts noto-fonts-emoji nerd-fonts
echo "Enabling necessary services (except ZeroTier One, it is not necessary, but will still be activated)..."
sleep 1
systemctl --user enable --now pipewire
systemctl --user enable --now wireplumber
sudo systemctl enable --now zerotier-one
echo "Installing yay..."
sleep 1
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd $HOME
echo "Installing a few pacakges from AUR using yay..."
sleep 1
yay --noconfirm -Syyu vesktop-bin upscaler bottles brave-bin
echo "Installing OpenTabletDriver"
sleep 1
git clone https://aur.archlinux.org/opentabletdriver.git
cd opentabletdriver && makepkg -si
cd $HOME
sudo mkinitcpio -P && sudo rmmod wacom hid_uclogic
rm -rf yay/ opentablerdriver/
