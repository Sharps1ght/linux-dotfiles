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
echo "YOU called it upon yourself"
sleep 3
echo "Applying configs..."
cd .. && cp -rf $HOME/linux-dotfiles/* $HOME/.config
echo "Updating package databases and upgrading installed packages..."
sudo pacman --noconfirm -Syyu
echo "Installing the essentials..."
sudo pacman --needed --noconfirm -S linux linux-headers linux-lts linux-lts-headers 7zip amd-ucode base base-devel btop fastfetch gtk2 gtk3 gtk4 hyprland hyprcursor hyprlang hyprpaper hyprpicker hyprpolkitagent hyprshot hyprutils imagemagick jre8-openjdk jdk-openjdk kitty neovim networkmanager noto-fonts ntfs-3g nerd-fonts nvidia nvidia-utils openvpn os-prober pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi-wayland steam steam-native-runtime sudo swaync telegram-desktop wayland wireplumber wl-clipboard xdg-desktop-portal xdg-desktop-portal-hyprland zerotier-one
echo "Enabling necessary services (except ZeroTier One, it is not necessary)..."
sudo systemctl enable --now pipewire
sudo systemctl enable --now wireplumber
sudo systemctl enable --now zerotier-one
echo "Installing yay..."
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si && cd ..
rm -rf yay
git clone https://aur.archlinux.org/opentabletdriver.git
cd opentabletdriver && makepkg -si && cd ..
rm -rf opentabletdriver
