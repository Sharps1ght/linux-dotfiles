#!/usr/bin/env bash

repo="$(pwd)"

for element in $(find $repo/.config -type f); do
	result="$(echo $element | sed "s|^$(pwd)|$HOME|")"
	cp -r $element $result
	echo "$result done"
done
