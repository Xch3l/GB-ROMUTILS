#!/usr/bin/env bash

# Vars so as not to clog PATH
wla_cpu=$HOME/bin/wladx/wla-gb
wlalink=$HOME/bin/wladx/wlalink

# Get current dir name
dirname=${PWD##*/}
dirname=${dirname:-/}

# Check rebuild flag
[ "$1" = "-r" ]; rm -f "$dirname.gb" *.lst *.sym

# Back up previous build
if [ -f "$dirname.gb" ]; then
	mkdir -p old
	num=1

	while [ -f "old/${dirname}_$num.gb" ]; do
		num=$(($num+1))
	done

	mv "$dirname.gb" "old/${dirname}_$num.gb"
fi

# Create object file
echo Creating object file...
$wla_cpu -x -D _DATE_=" $(date +'%Y-%m-%d')" -D _TIME_=" $(date +'%H:%M:%S')" -o $dirname.o ./main.asm

# Stop if that failed
result=$?
[ $result -eq 0 ] || exit $result

# Generate linker script
echo [objects]>linkfile
echo $dirname.o>>linkfile

# Link everything
echo Linking...
$wlalink -S -v linkfile $dirname.gb

# Clean up
rm $dirname.o linkfile
