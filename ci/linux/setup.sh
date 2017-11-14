#!/bin/bash
set -e

scriptdir=$(dirname $0)

echo FROM ubuntu:latest > $scriptdir/Dockerfile
#TODO pass all known vars
echo ENV \
	TRAVIS_OS_NAME=\"$TRAVIS_OS_NAME\" \
	QT_VER=\"$QT_VER\" \
	PLATFORM=\"$PLATFORM\" \
	EXTRA_MODULES=\"$EXTRA_MODULES\" \
	STATIC_QT_MODS=\"$STATIC_QT_MODS\" \
	STATIC_EXTRA_MODS=\"$STATIC_EXTRA_MODS\" >> $scriptdir/Dockerfile

echo "ADD setup /tmp/qt/setup/" >> $scriptdir/Dockerfile
echo "RUN /tmp/qt/setup/setup-docker.sh" >> $scriptdir/Dockerfile
echo "CMD cd /root/project && /root/project/qtmodules-travis/ci/linux/build-docker.sh" >> $scriptdir/Dockerfile

sudo docker build -t skycoder42/qt-build $scriptdir
