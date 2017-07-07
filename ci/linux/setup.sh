#!/bin/bash
set -e

scriptdir=$(dirname $0)

echo FROM ubuntu:latest > $scriptdir/Dockerfile
echo ENV QT_VER=$QT_VER >> $scriptdir/Dockerfile
echo ENV PROJECT=$PROJECT >> $scriptdir/Dockerfile
echo ENV EXCLUDE_PLATFORMS=$EXCLUDE_PLATFORMS >> $scriptdir/Dockerfile
echo ENV TEST_DIR=$TEST_DIR >> $scriptdir/Dockerfile
echo ENV NO_TESTS=$NO_TESTS >> $scriptdir/Dockerfile
cat $scriptdir/Dockerfile-base >> $scriptdir/Dockerfile

sudo docker build -t skycoder42/qt-build $scriptdir
