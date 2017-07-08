#!/bin/bash
set -e

qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
docker pull skycoder42/qt-build:qt$qtvid
