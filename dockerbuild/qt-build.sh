#!/bin/sh

cd ~
rm -rf build

set -e

mkdir -p $BUILD_INSTALL_DIR

mkdir build
cd build
git clone --recurse-submodules "$BUILD_GIT_SRC" .

qmake
make qmake_all
make
make INSTALL_ROOT="$BUILD_INSTALL_DIR" install