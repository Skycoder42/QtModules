#!/bin/bash
set -e

export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"

scriptdir=$(dirname $0)

if [[ $EXCLUDE_PLATFORMS != *"mac"* ]]; then
	$scriptdir/build-all.sh clang_64
fi

if [[ $EXCLUDE_PLATFORMS != *"ios"* ]]; then
	$scriptdir/build-first.sh ios
fi
