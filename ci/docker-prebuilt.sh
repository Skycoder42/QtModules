#!/bin/bash
# $1 Qt Version
# $2 suffix
# $3.. platforms (optional)
set -e

scriptdir=$(dirname $0)

export QT_VER=$1
export TRAVIS_OS_NAME=linux
export EXTRA_MODULES=".qtremoteobjects"
export STATIC_QT_MODS="qtwebsockets qtscxml qtremoteobjects"
export EXTRA_PKG="libsecret-1-dev libsystemd-dev"
export IMAGE_TAG=$2

shift
shift
PLATFORMS=${@:-gcc_64 android_armv7 android_x86}

case "$IMAGE_TAG" in
	full)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42"
		;;
	datasync)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.datasync"
		;;
	json)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.jsonserializer"
		;;
	base)
		# no extra exports
		;;
	lts)
		export IS_LTS=true
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
