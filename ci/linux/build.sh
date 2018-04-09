#!/bin/bash
set -e

if [ -z "$DOCKER_IMAGE" ]; then
	image=skycoder42/qt-build
else
	image="skycoder42/qt-build:${QT_VER}-${PLATFORM}-${DOCKER_IMAGE}"
fi

docker run --rm --name docker-qt-build -e QMAKE_FLAGS -e BUILD_DOC -e BUILD_EXAMPLES -e TEST_DIR -e NO_TESTS -e "QPMX_CACHE_DIR=/root/.qpmx-cache" -v "$(pwd):/root/project" -v "$QPMX_CACHE_DIR:/root/.qpmx-cache" "$image"
sudo chown -R $USER $(pwd)
sudo chown -R $USER $QPMX_CACHE_DIR
