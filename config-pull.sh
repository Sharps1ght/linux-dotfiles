#!/usr/bin/env bash

for element in $(find $(pwd)/.config -type f); do
	target="$(echo $element | sed "s|^$(pwd)|$HOME|")"
	cp -r $target $element
	echo "$target... done!"
done
