#!/bin/bash
# $1 Qt Version
# $2 suffix
# $3.. platforms (optional)
set -e

scriptdir=$(dirname $0)

export QT_VER=$1
export TRAVIS_OS_NAME=linux
export EXTRA_MODULES=""
export STATIC_QT_MODS="qtwebsockets qtscxml qtremoteobjects"
export EXTRA_PKG="libsecret-1-dev libsystemd-dev"
export IMAGE_TAG=$2

shift
shift
PLATFORMS=${@:-gcc_64 android_arm64_v8a android_armv7 android_x86 emscripten}

case "$IMAGE_TAG" in
	full)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42"
		EMSCRIPTEN_IMAGE_BASE="skycoder42/qt-build:${QT_VER}-emscripten-datasync"
		export EMSCRIPTEN_EXTRA_MODS="$EMSCRIPTEN_EXTRA_MODS qtrestclient qtmvvm qtapng"
		;;
	datasync)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.datasync"
		EMSCRIPTEN_IMAGE_BASE="skycoder42/qt-build:${QT_VER}-emscripten-common"
		export EMSCRIPTEN_EXTRA_MODS="$EMSCRIPTEN_EXTRA_MODS datasync"
		;;
	common)
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.jsonserializer .skycoder42.service"
		EMSCRIPTEN_IMAGE_BASE="skycoder42/qt-build:${QT_VER}-emscripten-base"
		export EMSCRIPTEN_EXTRA_MODS="$EMSCRIPTEN_EXTRA_MODS qtjsonserializer qtservice"
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
	if [ "$platform" == "emscripten" ]; then
		export DOCKER_IMAGE_BASE=$EMSCRIPTEN_IMAGE_BASE
	else
		export DOCKER_IMAGE_BASE=
	fi
	
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	$scriptdir/linux/setup.sh
	
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	sudo docker push "skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_TAG}"
done

paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
sudo docker system prune -a
