#!/bin/bash
# $1 platform
# $2 compiler
set -e

platform=$1
compiler=$2

mkdir build-$platform
cd build-$platform

/opt/qt/$QT_VER/$platform/bin/qmake -r "$compiler" ../$PROJECT.pro
make
make INSTALL_ROOT="$(pwd)/../install" install
