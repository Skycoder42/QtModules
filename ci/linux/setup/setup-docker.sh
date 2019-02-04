#!/bin/bash
set -e

scriptdir=$(dirname $0)

# flatpak: build that only, then return
if [[ "$PLATFORM" == "flatpak" ]]; then
	exec $scriptdir/setup-flatpak.sh
	exit 1
fi

## common setup
if [[ $PLATFORM == "emscripten" ]]; then
	$scriptdir/setup-wasm.sh
elif [ -n "$BASE_IMAGE" ]; then
	# gcc_64 only -> install qtifw
	if [[ $PLATFORM == "gcc_64" ]]; then
		export EXTRA_MODULES="qt.tools.ifw.30 $EXTRA_MODULES"
	fi

	$scriptdir/setup-common.sh

	## platform-specific setup
	export MAKEFLAGS="-j$(nproc)"
	if [[ $PLATFORM == "gcc_64" ]]; then
		$scriptdir/setup-gcc.sh
	fi

	if [[ $PLATFORM == "android_"* ]]; then
		$scriptdir/setup-android.sh
	fi
else
	$scriptdir/setup-modules.sh
fi

rm -rf /tmp/*
