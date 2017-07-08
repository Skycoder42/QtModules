#!/bin/bash
set -e

docker run --rm --name docker-qt-build -e PROJECT -e EXCLUDE_PLATFORMS -e TEST_DIR -e NO_TESTS -v "$(pwd):/root/project" skycoder42/qt-build
