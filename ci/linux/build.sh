#!/bin/bash
set -e

docker run --rm --name docker-qt-build -e QMAKE_FLAGS -e BUILD_DOC -e TEST_DIR -e NO_TESTS -v "$(pwd):/root/project" skycoder42/qt-build
sudo chown -R $USER $(pwd)
