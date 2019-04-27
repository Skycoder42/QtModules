#!/bin/sh
# $1 Qt Version
# $2 suffix
# $3.. platforms (optional)
set -e

scriptdir=$(dirname $0)

export QT_VER=$1
export TRAVIS_OS_NAME=linux
export EXTRA_MODULES=""
export EMSCRIPTEN_EXTRA_MODULES=""
export EXTRA_PKG=""
export IMAGE_TAG=$2

shift
shift

case "$IMAGE_TAG" in
	full)
		PLATFORMS=${@:-gcc_64 android_arm64_v8a android_armv7 android_x86 emscripten}
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42"
		export EMSCRIPTEN_EXTRA_MODULES="$EMSCRIPTEN_EXTRA_MODULES qtrestclient qtmvvm qtapng"
		IMAGE_BASE=datasync
		;;
	datasync)
		PLATFORMS=${@:-gcc_64 android_arm64_v8a android_armv7 android_x86}
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.datasync"
		export EMSCRIPTEN_EXTRA_MODULES="$EMSCRIPTEN_EXTRA_MODULES qtdatasync"
		IMAGE_BASE=common
		;;
	common)
		PLATFORMS=${@:-gcc_64 android_arm64_v8a android_armv7 android_x86 emscripten}
		export EXTRA_MODULES="$EXTRA_MODULES .skycoder42.jsonserializer .skycoder42.service"
		export EMSCRIPTEN_EXTRA_MODULES="$EMSCRIPTEN_EXTRA_MODULES qtjsonserializer qtservice"
		IMAGE_BASE=base
		;;
	base)
		PLATFORMS=${@:-gcc_64 android_arm64_v8a android_armv7 android_x86 emscripten}
		export BASE_IMAGE=true
		;;
	lts)
		PLATFORMS=${@:-gcc_64 android_armv7 android_x86}
		export BASE_IMAGE=true
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
		if [ "$IMAGE_TAG" == "full" ] && [ "$platform" == "emscripten" ]; then  # for use of different base image for emscripten build
			export DOCKER_IMAGE_BASE="skycoder42/qt-build:${QT_VER}-${PLATFORM}-common"
		else
			export DOCKER_IMAGE_BASE="skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_BASE}"
		fi
	else
		export DOCKER_IMAGE_BASE=
	fi
	
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	$scriptdir/linux/setup.sh
	
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	sudo docker push "skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_TAG}"
done

if [ "$IMAGE_TAG" == "full" ] || [ "$IMAGE_TAG" == "lts" ]; then
	paplay /usr/share/sounds/Oxygen-Sys-App-Message.ogg || true
	sudo docker system prune -a
fi
