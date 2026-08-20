#!/usr/bin/env bash
echo "This script pulls from your current ~/.config/ directory to this repo"
echo "Press CTRL+C to cancel in the next 10 seconds"
for i in {1..10}; do
	sleep 1
done

for element in $(find $(pwd)/.config -type f); do
	target="$(echo $element | sed "s|^$(pwd)|$HOME|")"
	cp -r $target $element
	echo "$target... done!"
done
