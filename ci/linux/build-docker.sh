#!/bin/bash
set -e

export MAKEFLAGS="-j$(nproc)"
export ANDROID_HOME=$HOME/android/sdk
export ANDROID_NDK=$HOME/android/sdk/ndk-bundle
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_NDK_ROOT=$ANDROID_NDK

if [[ -z "$TEST_DIR" ]]; then
	export TEST_DIR=./tests/auto
fi

olddir=$(pwd)
for file in $(find . -name "qpm.json"); do
	qpmdir=$(dirname $file)
	if [[ "$qpmdir" != *"vendor"* ]]; then
		cd $qpmdir
		qpm install
		cd $olddir
	fi
done

scriptdir=$(dirname $0)
if [[ $EXCLUDE_PLATFORMS != *"linux"* ]]; then
	if [[ -z "$NO_TESTS" ]]; then
		$scriptdir/build-all.sh gcc_64 "QMAKE_LFLAGS+=-no-pie"
	else
		$scriptdir/build-first.sh gcc_64 "QMAKE_LFLAGS+=-no-pie"
	fi
fi

if [[ $EXCLUDE_PLATFORMS != *"android"* ]]; then
	$scriptdir/build-first.sh android_armv7
	$scriptdir/build-first.sh android_x86
fi

if [[ $EXCLUDE_PLATFORMS != *"doc"* ]]; then
	$scriptdir/build-doc.sh gcc_64
fi
