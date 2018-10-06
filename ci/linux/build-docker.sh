#!/bin/bash
set -e

scriptdir=$(dirname $0)

# branch out for flatpak
if [[ $PLATFORM == "flatpak" ]]; then
	exec "$scriptdir/build-flatpak.sh"
	exit 1
fi

# setup environment
export MAKEFLAGS="-j$(nproc)"

if [[ $PLATFORM == "android_"* ]]; then
	export ANDROID_HOME=$HOME/android/sdk
	export ANDROID_NDK=$HOME/android/sdk/ndk-bundle
	export ANDROID_SDK_ROOT=$ANDROID_HOME
	export ANDROID_NDK_ROOT=$ANDROID_NDK

	export NO_TESTS=true
fi

if [[ $PLATFORM == "static" ]]; then
	export NO_TESTS=true
	echo "CONFIG += static_host_build" >> .qmake.conf
fi

# build
rootdir=$(pwd)
mkdir build-$PLATFORM
pushd build-$PLATFORM

/opt/qt/$QT_VER/$PLATFORM/bin/qmake "CONFIG+=no_auto_lupdate" "QT_PLATFORM=$PLATFORM" $QMAKE_FLAGS ../
make qmake_all
make
make lrelease
make INSTALL_ROOT="$rootdir/install" install

# build and run tests
if [[ -z "$NO_TESTS" ]] && [[ -n "$MAKE_RUN_TESTS" ]]; then
	export NO_TESTS=true
	
	export LD_LIBRARY_PATH="/usr/lib/openssl-1.0:$LD_LIBRARY_PATH"
	
	make all # will also build examples (but not run them)
	make -j1 run-tests
fi

# build and run tests (deprecated)
if [[ -z "$NO_TESTS" ]]; then
	make all # will also build examples (but not run them)

	export LD_LIBRARY_PATH="/usr/lib/openssl-1.0:$(pwd)/lib:/opt/qt/$QT_VER/$PLATFORM/lib:$LD_LIBRARY_PATH"
	export QT_PLUGIN_PATH="$(pwd)/plugins:$QT_PLUGIN_PATH"

	if [[ -z "$TEST_DIR" ]]; then
		export TEST_DIR=./tests/auto
	fi
	pushd "$TEST_DIR"
	for test in $(find . -type f -executable -name "tst_*"); do
		QT_QPA_PLATFORM=minimal $test
	done
	popd
fi

# build examples
if [[ -n "$BUILD_EXAMPLES" ]]; then
	make sub-examples #build only examples, no tests again

	pushd examples
	make INSTALL_ROOT="$rootdir/install" install
	popd
fi

# build documentation
if [[ -n "$BUILD_DOC" ]]; then
	make doxygen
	
	pushd doc
	make INSTALL_ROOT="$rootdir/install" install
	popd
fi

popd
