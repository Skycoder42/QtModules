#!/bin/bash
set -e

if [ -z "$DOCKER_IMAGE" ]; then
	image=skycoder42/qt-build
else
	image="skycoder42/qt-build:${QT_VER}-${PLATFORM}-${DOCKER_IMAGE}"
fi

docker run --rm --name docker-qt-build -e QMAKE_FLAGS -e BUILD_DOC -e BUILD_EXAMPLES -e TEST_DIR -e NO_TESTS -v "$(pwd):/root/project" "$image"
sudo chown -R $USER $(pwd)
