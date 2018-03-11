#!/bin/bash
# $1 Qt Version
# $2 suffix
set -e

scriptdir=$(dirname $0)

export QT_VER=$1
export TRAVIS_OS_NAME=linux
export IMAGE_TAG=$2

case "$IMAGE_TAG" in
	datasync)
		export EXTRA_MODULES=".qtremoteobjects .skycoder42.datasync"
		;;
	base)
		# no extra exports
		;;
	*)
		echo "INVALID suffix!"
		exit 1
		;;
esac

for platform in gcc_64; do #android_armv7 android_x86; do
	export PLATFORM=$platform
	$scriptdir/linux/setup.sh
	sudo docker push "skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_TAG}"
done
