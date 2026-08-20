#!/usr/bin/env bash
echo "This script pulls to your current ~/.config/ directory from this repo"
echo "Press CTRL+C to cancel in the next 10 seconds"
for i in {1..10}; do
	sleep 1
done

for element in $(find $(pwd)/.config -type f); do
	target="$(echo $element | sed "s|^$(pwd)|$HOME|")"
	if [[ $(stat -c%s $target) -ne $(stat -c%s $element) ]]; then
		cp -r $element $target
		echo "$target... done!"
	else
		continue
	fi
done
