#!/bin/bash
set -e

sudo docker run --rm --name docker-qt-build -v "$(pwd):/root/project" skycoder42/qt-build
