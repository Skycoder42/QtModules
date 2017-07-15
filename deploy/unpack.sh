#!/bin/sh
# $1 target folder

tDir=$1
mkdir -p "$tDir"

for file in archives/*.tar.xz; do
	tar -xf $file -C "$tDir"
done

for file in archives/*.zip; do
	unzip -qq $file -d "$tDir"
done
