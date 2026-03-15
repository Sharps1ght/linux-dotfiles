#!/usr/bin/env bash

for element in $(find $(pwd)/.config -type f); do
	fileName=$(basename $element)
	if [[ $(stat -c%s $element) -ne $(stat -c%s $(find $HOME/.config -type f 
		cp $(find $HOME/.config -type f -name $fileName) $element
done
