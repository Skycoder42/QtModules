#!/bin/bash
# $1 Qt Version
# $2 suffix
# $3.. platforms (optional)
set -e

scriptdir=$(dirname $0)

export QT_VER=$1
export TRAVIS_OS_NAME=linux
export IMAGE_TAG=$2
#export IS_LTS=true

shift
shift
PLATFORMS=${@:-gcc_64 android_armv7 android_x86}

case "$IMAGE_TAG" in
	full)
		export EXTRA_MODULES=".qtremoteobjects .skycoder42"
		;;
	datasync)
		export EXTRA_MODULES=".qtremoteobjects .skycoder42.datasync"
		;;
	json)
		export EXTRA_MODULES=".skycoder42.jsonserializer"
		;;
	base)
		# no extra exports
		;;
	*)
		echo "INVALID suffix!"
		exit 1
		;;
esac

for platform in $PLATFORMS; do
	echo building $IMAGE_TAG for $platform
	export PLATFORM=$platform
	$scriptdir/linux/setup.sh
	sudo docker push "skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_TAG}"
done
