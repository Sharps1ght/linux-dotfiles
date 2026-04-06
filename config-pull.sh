#!/usr/bin/env bash
for i in {1..30}; do
	sleep 1
done

for element in $(find $(pwd)/.config -type f); do
	target="$(echo $element | sed "s|^$(pwd)|$HOME|")"
	cp -r $target $element
	echo "$target... done!"
done
