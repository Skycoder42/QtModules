#!/bin/bash
set -e

scriptdir=$(dirname $0)

## common setup
$scriptdir/setup-common.sh

## platform-specific setup
if [[ $PLATFORM == "gcc_64" ]]; then
	$scriptdir/setup-gcc.sh
fi

if [[ $PLATFORM == "android_"* ]]; then
	$scriptdir/setup-android.sh
fi

if [[ $PLATFORM == "static" ]]; then
	$scriptdir/setup-static.sh
fi

sudo rm -rf /tmp/*
