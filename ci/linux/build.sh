#!/bin/bash
set -e

if [ -z "$DOCKER_IMAGE" ]; then
	image=skycoder42/qt-build
else
	image="skycoder42/qt-build:${QT_VER}-${PLATFORM}-${DOCKER_IMAGE}"
fi

if [ -z "$NO_DOCKER_RM" ]; then
	drm=--rm
fi


sudo docker run $drm --name docker-qt-build --device /dev/fuse --cap-add ALL -e QMAKE_FLAGS -e BUILD_DOC -e BUILD_EXAMPLES -e TEST_DIR -e NO_TESTS -e MAKE_RUN_TESTS -e FLATPAK_MANIFEST -e "QPMX_CACHE_DIR=/root/.qpmx-cache" -v "$(pwd):/root/project" -v "$QPMX_CACHE_DIR:/root/.qpmx-cache" "$image"
sudo chown -R $USER $(pwd)
sudo chown -R $USER $QPMX_CACHE_DIR
