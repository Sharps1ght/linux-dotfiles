#!/usr/bin/env bash

for element in $(find $(pwd)/.config -type f); do
	fileName=$(basename $element)
	cp $(find $HOME/.config -type f -name $fileName) $(find ./.config/ -type f -name $fileName)
done
