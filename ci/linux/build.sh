#!/bin/bash
set -e

qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
docker run --rm --name docker-qt-build -e PROJECT -e EXCLUDE_PLATFORMS -e TEST_DIR -e NO_TESTS -v "$(pwd):/root/project" skycoder42/qt-build:qt$qtvid

sudo chown -r $USER $(pwd)
