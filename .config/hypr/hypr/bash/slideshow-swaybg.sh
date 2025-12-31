#!/usr/bin/env bash

wallpaperDir="$HOME/Pictures/Wallpapers/"
monitors=$(hyprctl monitors | grep Monitor | awk '{print $2}')
timer=30

pkill swaybg
for display in $monitors; do
	wallpaper=$(find "$wallpaperDir" -type f | shuf -n 1)
	hyprctl dispatch exec "swaybg -o $display -m fill -i $wallpaper"
done
sleep $timer
while true; do
	for display in $monitors; do
	wallpaper=$(find "$wallpaperDir" -type f ! -name $(basename $(ps -C swaybg -o args= | grep $display | awk '{print $7}')) | shuf -n 1)
	hyprctl dispatch exec "swaybg -o $display -m fill -i $wallpaper"
	sleep $(( $timer - ($timer - 1) ))
	ps -eo pid,cmd | grep swaybg | grep $display | sort -n | head -n1 | awk '{print $1}' | xargs -r kill
	sleep $timer
	done
done
