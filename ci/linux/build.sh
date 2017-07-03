#!/bin/bash
set -e

export MAKEFLAGS="-j$(nproc)"
export ANDROID_HOME=$HOME/android/sdk
export ANDROID_NDK=$HOME/android/sdk/ndk-bundle
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_NDK_ROOT=$ANDROID_NDK

scriptdir=$(dirname $0)
needs_doc=0

if [[ $EXCLUDE_PLATFORMS != *"linux"* ]]; then
	$scriptdir/build-all.sh gcc_64 "QMAKE_CXX=g++-5"
	if (( needs_doc == 0 )); then
		$scriptdir/build-doc.sh gcc_64
		needs_doc=1
	fi
fi

if [[ $EXCLUDE_PLATFORMS != *"android"* ]]; then
	$scriptdir/build-first.sh android_armv7
	$scriptdir/build-first.sh android_x86
	if (( needs_doc == 0 )); then
		$scriptdir/build-doc.sh android_armv7
		needs_doc=1
	fi
fi
