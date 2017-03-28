#!/bin/sh
# $1 git repository
# $2 local install directory

docker run --name docker-qt-build -v "$2:/tmp/qt-build/inst" -e "BUILD_GIT_SRC=$1" skycoder42/qt-build
docker rm docker-qt-build