#!/bin/bash
# $1 Qt Version
# $2 suffix
# $3.. platforms (optional)
set -e

scriptdir=$(dirname $0)

export QT_VER=$1
export TRAVIS_OS_NAME=linux
export EXTRA_MODULES=""
export EMSCRIPTEN_EXTRA_MODULES=""
export EXTRA_PKG="libsecret-1-dev libsystemd-dev"
export IMAGE_TAG=$2

shift
shift
PLATFORMS=${@:-gcc_64 android_arm64_v8a android_armv7 android_x86 emscripten}

case "$IMAGE_TAG" in
	full)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42"
		export EMSCRIPTEN_EXTRA_MODULES="$EMSCRIPTEN_EXTRA_MODULES qtrestclient qtmvvm qtapng"
		IMAGE_BASE=datasync
		;;
	datasync)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.datasync"
		export EMSCRIPTEN_EXTRA_MODULES="$EMSCRIPTEN_EXTRA_MODULES datasync"
		IMAGE_BASE=common
		;;
	common)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.jsonserializer .skycoder42.service"
		export EMSCRIPTEN_EXTRA_MODULES="$EMSCRIPTEN_EXTRA_MODULES qtjsonserializer qtservice"
		IMAGE_BASE=base
		;;
	base)
		export BASE_IMAGE=true
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
	if [ -n "$IMAGE_BASE" ]; then
		export DOCKER_IMAGE_BASE="skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_BASE}"
	else
		export DOCKER_IMAGE_BASE=
	fi
	
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	$scriptdir/linux/setup.sh
	
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	sudo docker push "skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_TAG}"
done

if [[ "$IMAGE_TAG" == "full" ]]; then
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	sudo docker system prune -a
fi
