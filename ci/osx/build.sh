#!/bin/bash
set -e

scriptdir=$(dirname $0)

export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"

# ios: no tests
if [[ $PLATFORM == "ios" ]]; then
	export NO_TESTS=true
fi

# install QPM dependencies
olddir=$(pwd)
for file in $(find . -name "qpm.json"); do
	qpmdir=$(dirname $file)
	if [[ "$qpmdir" != *"vendor"* ]]; then
		cd $qpmdir
		qpm install
		cd $olddir
	fi
done

# build
rootdir=$(pwd)
mkdir build-$PLATFORM
cd build-$PLATFORM

/opt/qt/$QT_VER/$PLATFORM/bin/qmake -r $QMAKE_FLAGS ../
make
make INSTALL_ROOT="$rootdir/install" install

# build and run tests
if [[ -z "$NO_TESTS" ]]; then
	make all

	export LD_LIBRARY_PATH="$(pwd)/lib:/opt/qt/$QT_VER/$PLATFORM/lib:$LD_LIBRARY_PATH"

	if [[ -z "$TEST_DIR" ]]; then
		export TEST_DIR=./tests/auto
	fi
	cd "$TEST_DIR"
	for test in $(find . -type f -perm +0111 -name "tst_*"); do
		#QT_QPA_PLATFORM=minimal
		$test
	done
fi

# build documentation
if [[ -n "$BUILD_DOC" ]]; then
	cd "$rootdir"
	mkdir build-doc
	cd build-doc

	/opt/qt/$QT_VER/$PLATFORM/bin/qmake -r ../doc/doc.pro
	make doxygen
	make INSTALL_ROOT="$rootdir/install" install
fi
