#!/bin/bash
set -e

export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"

if [[ -z "$TEST_DIR" ]]; then
	export TEST_DIR=./tests/auto
fi

olddir=$(pwd)
for file in $(find . -name "qpm.json"); do
	qpmdir=$(dirname $file)
	if [[ "$qpmdir" != *"vendor"* ]]; then
		cd $qpmdir
		qpm install
	fi
done
cd $olddir

scriptdir=$(dirname $0)

if [[ $EXCLUDE_PLATFORMS != *"mac"* ]]; then
	if [[ -z "$NO_TESTS" ]]; then
		$scriptdir/build-all.sh clang_64
	else
		$scriptdir/build-first.sh clang_64
	fi
fi

if [[ $EXCLUDE_PLATFORMS != *"ios"* ]]; then
	$scriptdir/build-first.sh ios
fi
