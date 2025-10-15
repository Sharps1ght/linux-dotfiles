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
sudo pacman --needed --noconfirm -S ark thunar base-devel btop dotnet-runtime fastfetch gtk2 gtk3 gtk4 hyprland hyprcursor hypridle hyprlang hyprlock hyprpaper hyprpicker hyprpolkitagent hyprshot hyprutils imagemagick jre8-openjdk jdk-openjdk kitty mako neovim noto-fonts ntfs-3g nerd-fonts nvidia nvidia-utils openvpn pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi-wayland sudo telegram-desktop uwsm vlc wayland wireplumber wl-clipboard xdg-desktop-portal xdg-desktop-portal-hyprland zerotier-one noto-fonts noto-fonts-emoji nerd-fonts
sleep 1
echo "Installing yay..."
sleep 1
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd .. && rm -rf yay
sleep 1
echo "Installing OpenTablerDriver..."
sleep 1
git clone https://aur.archlinux.org/opentabletdriver.git
cd opentabletdriver && dotnet workload update && makepkg -si
cd ..
rm -rf opentabletdriver
sudo mkinitcpio -P
sudo rmmod wacom hid_uclogic
