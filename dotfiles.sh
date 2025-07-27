cd .. && cp -rf $HOME/linux-dotfiles/* $HOME/.config
sudo pacman -Syyu
sudo pacman --needed --noconfirm -S linux linux-headers linux-lts linux-lts-headers 7zip amd-ucode base base-devel btop fastfetch gtk2 gtk3 gtk4 hyprland hyprcursor hyprlang hyprpaper hyprpicker hyprpolkitagent hyprshot hyprutils imagemagick jre8-openjdk jdk-openjdk kitty neovim networkmanager noto-fonts ntfs-3g nerd-fonts nvidia nvidia-utils openvpn os-prober pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse qt5-wayland qt6-wayland rofi-wayland steam steam-native-runtime sudo swaync telegram-desktop wayland wireplumber wl-clipboard xdg-desktop-portal xdg-desktop-portal-hyprland zerotier-one
sudo systemctl enable --now pipewire
sudo systemctl enable --now wireplumber
sudo systemctl enable --now zerotier-one
