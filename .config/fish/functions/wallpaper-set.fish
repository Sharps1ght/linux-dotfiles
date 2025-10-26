function wallpaper-set
	if test (count $argv) -ne 2
		echo "Usage: wallpaper set <DISPLAY> <PATH>"
		return 1
	end

	set display $argv[1]
	set dir $argv[2]

	hyprctl hyprpaper unload all && \
	hyprctl hyprpaper preload "$dir" && \
	hyprctl hyprpaper wallpaper "$display,$dir"
end

