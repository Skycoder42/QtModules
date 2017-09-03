#!/bin/bash
set -e

scriptdir=$(dirname $0)

echo FROM ubuntu:latest > $scriptdir/Dockerfile
echo ENV QT_VER=\"$QT_VER\" PLATFORM=\"$PLATFORM\" EXTRA_MODULES=\"qt.tools.ifw.20 $EXTRA_MODULES\" STATIC_QT_MODS=\"$STATIC_QT_MODS\" STATIC_EXTRA_MODS=\"$STATIC_EXTRA_MODS\" >> $scriptdir/Dockerfile
cat $scriptdir/Dockerfile-base >> $scriptdir/Dockerfile

sudo docker build -t skycoder42/qt-build $scriptdir
