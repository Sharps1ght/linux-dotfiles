#!/usr/bin/env bash

wallpaperDir="$HOME/Pictures/Wallpapers/"
currentWall=$(hyprctl hyprpaper listactive)
monitors=$(hyprctl monitors | grep Monitor | awk '{print $2}')
timer=30

sleep 1
for display in $monitors; do
	wallpaper=$(find "$wallpaperDir" -type f ! -name "$(basename "$(hyprctl hyprpaper listactive | grep $display)")" | shuf -n 1)
	hyprctl hyprpaper reload "$display","$wallpaper"
done
sleep $timer
while true; do
	for display in $monitors; do
		wallpaper=$(find "$wallpaperDir" -type f ! -name "$(basename "$(hyprctl hyprpaper listactive | grep $display)")" | shuf -n 1)
		hyprctl hyprpaper reload "$display","$wallpaper"
		sleep $timer
	done
done
