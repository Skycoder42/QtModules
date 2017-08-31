#!/bin/bash
set -e

scriptdir=$(dirname $0)

if [[ $PLATFORM == "gcc_64" ]]; then
	docker run --rm --name docker-qt-build -e BUILD_DOC -e TEST_DIR -e NO_TESTS -v "$(pwd):/root/project" skycoder42/qt-build
	sudo chown -R $USER $(pwd)
fi

if [[ $PLATFORM == "android_"* ]]; then
	export ANDROID_HOME=$HOME/android/sdk
	export ANDROID_NDK=$HOME/android/sdk/ndk-bundle
	export ANDROID_SDK_ROOT=$ANDROID_HOME
	export ANDROID_NDK_ROOT=$ANDROID_NDK

	export NO_TESTS=true

	$scriptdir/build-all.sh
fi

if [[ $PLATFORM == "static" ]]; then
	docker run --rm --name docker-qt-build -e BUILD_DOC -e TEST_DIR -e NO_TESTS -v "$(pwd):/root/project" skycoder42/qt-build
	sudo chown -R $USER $(pwd)
fi
