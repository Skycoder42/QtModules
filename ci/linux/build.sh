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

mkdir -p "$QDEP_CACHE_DIR"
sudo docker run $drm --name docker-qt-build --device /dev/fuse --cap-add ALL \
	-e QMAKE_FLAGS \
	-e BUILD_DOC \
	-e BUILD_EXAMPLES \
	-e TEST_DIR \
	-e NO_TESTS \
	-e MAKE_RUN_TESTS \
	-e LTS_MODS \
	-e NO_FLATDEP \
	-e FLATDEP_DIR \
	-e FLATPAK_MANIFEST \
	-e "QDEP_CACHE_DIR=/root/.qdep-cache" \
	-v "$(pwd):/root/project" \
	-v "$QDEP_CACHE_DIR:/root/.qdep-cache" "$image"
sudo chown -R $USER $(pwd)
sudo chown -R $USER $QDEP_CACHE_DIR
