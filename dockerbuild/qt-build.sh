#!/bin/bash

cd ~
rm -rf build

set -e

mkdir -p $BUILD_INSTALL_DIR

mkdir build
cd build
git clone --recurse-submodules "$BUILD_GIT_SRC" .

for path in ${QPM_PATH//:/ }; do
	cd $path
	qpm install
	cd ~/build
done

echo QMAKE_LFLAGS += -no-pie >> .qmake.conf
qmake
make qmake_all
make
make INSTALL_ROOT="$BUILD_INSTALL_DIR" install