#!/usr/bin/env bash

# Directory where wallpapers are pulled from 
wallpaperDir="$HOME/.config/hypr/Wallpapers/"
# Check which wallpapers are currently in use
currentWall=$(hyprctl hyprpaper listactive)
# List all monitors connected
monitors=$(hyprctl monitors | grep Monitor | awk '{print $2}')
# Amount of seconds that need to pass for wallpaper to be changed on ONE monitor
# Multiply by amount of monitors you have to find out how much time will pass before  a wallpaper will be swapped on THE monitor
timer=30

# Start an infinite loop
while true; do
	# Go through all of the connected monitors
	for display in $monitors; do
		# Call out the selected monitor
		echo "Changing $display..."
		# Pick a random wallpaper from directory (not fool-proof, theoretically can select ANY file)
		wallpaper=$(find "$wallpaperDir" -type f ! -name "$(basename "$(hyprctl hyprpaper listactive | grep $display)")" | shuf -n 1)
		# Call out the selected wallpaper
		echo "Picked $(basename $wallpaper)"
		# Apply selected wallpaper to selected monitor
		hyprctl hyprpaper reload "$display","$wallpaper"
		# Result
		echo "$display is set to $(basename $wallpaper)"
		# Timer
		sleep $timer
	done
	# Dunno why but unload all of the wallpapers
	# (it won't remove any currently active wallpapers from the monitors)
	hyprctl hyprpaper unload all
done
