#!/usr/bin/env bash
for i in {1..30}; do
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
