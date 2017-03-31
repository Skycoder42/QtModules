#!/bin/sh
# $1 git repository
# $2 local install directory
# $3 build mode (i.e. "" or "-native" )

image=skycoder42/qt-build$3
echo Building with image $image
docker run --rm --name docker-qt-build -v "$2:/tmp/qt-build/inst" -e "BUILD_GIT_SRC=$1" $image