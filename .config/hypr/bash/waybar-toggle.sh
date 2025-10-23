#!/usr/bin/env bash
APP="waybar"

if pgrep -x "$APP" >/dev/null; then
	pkill -x "$APP"
	# echo "waybar hidden"
else
	"$APP" >/dev/null 2>&1 &
	# echo "waybar shown"
fi
