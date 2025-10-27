#!/usr/bin/env bash

wallpaperDir="$HOME/Pictures/Wallpapers/"
currentWall=$(hyprctl hyprpaper listactive)
monitors=$(hyprctl monitors | grep Monitor | awk '{print $2}')
timer=30

sleep 3
while true; do
	for display in $monitors; do
		# echo "Changing $display..."
		# echo "$(hyprctl hyprpaper listactive | grep $display | basename $(awk '{print $3}')) is on $display."
		wallpaper=$(find "$wallpaperDir" -type f ! -name "$(basename "$(hyprctl hyprpaper listactive | grep $display)")" | shuf -n 1)
		# echo "Picked $(basename $wallpaper)"
		hyprctl hyprpaper reload "$display","$wallpaper"
		# echo "$display is set to $(basename $wallpaper)"
		sleep $timer
	done
done
