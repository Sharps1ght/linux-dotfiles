#!/usr/bin/env bash

wallpaperDir="$HOME/Pictures/Wallpapers/"
monitors=$(hyprctl monitors | grep Monitor | awk '{print $2}')
mode=fill
timer=30

sleep 1
for display in $monitors; do
	wallpaper=$(find "$wallpaperDir" -type f | shuf -n 1)
	hyprctl hyprpaper wallpaper "$display","$wallpaper, $mode"
done
sleep $timer
while true; do
	for display in $monitors; do
		wallpaper=$(find "$wallpaperDir" -type f | shuf -n 1)
		hyprctl hyprpaper wallpaper "$display","$wallpaper, $mode"
		sleep $timer
	done
done
