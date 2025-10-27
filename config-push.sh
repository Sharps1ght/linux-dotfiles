#!/usr/bin/env bash

for element in $(find $(pwd)/.config -type f); do
	result="$(echo $element | sed "s|^$(pwd)|$HOME|")"
	if [[ $(stat -c%s $result) -ne $(stat -c%s $element) ]]; then
		cp -r $element $result
		echo "$result... done!"
	else
		continue
	fi
done
