#!/bin/bash
set -e

scriptdir=$(dirname $0)

if [ "$PLATFORM" == "flatpak" ]; then
	export DOCKER_IMAGE=
    export DOCKER_IMAGE_BASE="base/archlinux:latest"
fi

if [ -z "$DOCKER_IMAGE" ]; then
	if [ -z "$DOCKER_IMAGE_BASE" ]; then
		echo FROM ubuntu:bionic > $scriptdir/Dockerfile
	else
		echo FROM "$DOCKER_IMAGE_BASE" > $scriptdir/Dockerfile
	fi
	#TODO pass all known vars
	echo ENV \
		TRAVIS_OS_NAME=\"$TRAVIS_OS_NAME\" \
		QT_VER_MINOR=\"$QT_VER_MINOR\" \
		QT_VER=\"$QT_VER\" \
		PLATFORM=\"$PLATFORM\" \
		IS_LTS=\"$IS_LTS\" \
		EXTRA_PKG=\"$EXTRA_PKG\" \
		EXTRA_MODULES=\"$EXTRA_MODULES\" \
		STATIC_QT_MODS=\"$STATIC_QT_MODS\" \
		STATIC_EXTRA_MODS=\"$STATIC_EXTRA_MODS\" \
		QMAKE_FLAGS=\"$QMAKE_FLAGS\" >> $scriptdir/Dockerfile

	echo "ADD setup /tmp/qt/setup/" >> $scriptdir/Dockerfile
	echo "RUN /tmp/qt/setup/setup-docker.sh" >> $scriptdir/Dockerfile
	echo "CMD cd /root/project && /root/project/qtmodules-travis/ci/linux/build-docker.sh" >> $scriptdir/Dockerfile

	if [ -z "$IMAGE_TAG" ]; then
		image=skycoder42/qt-build
	else
		image="skycoder42/qt-build:${QT_VER}-${PLATFORM}-${IMAGE_TAG}"
	fi
	sudo docker build --pull -t "$image" "$scriptdir"
else
	sudo docker pull "skycoder42/qt-build:${QT_VER}-${PLATFORM}-${DOCKER_IMAGE}"
fi
