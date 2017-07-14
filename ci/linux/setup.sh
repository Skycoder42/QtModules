#!/bin/bash
set -e

scriptdir=$(dirname $0)

if [[ $PLATFORM == "gcc_64" ]]; then
	$scriptdir/setup-gcc.sh
fi

if [[ $PLATFORM == "android_"* ]]; then
	$scriptdir/setup-android.sh
fi
