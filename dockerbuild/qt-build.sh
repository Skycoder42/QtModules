#!/bin/sh

cd ~
rm -rf build

set -e

mkdir -p $BUILD_INSTALL_DIR

mkdir build
cd build
git clone --recurse-submodules "$BUILD_GIT_SRC" .

for ex in src tools; do
	if [ -e $ex ]; then
		cd $ex
		for m in $(ls -d */); do
			mod=${m%%/}
			echo "CONFIG -= c++1z" >> ./$mod/$mod.pro
		done
		cd ..
	fi
done

qmake
make qmake_all
make
make INSTALL_ROOT="$BUILD_INSTALL_DIR" install