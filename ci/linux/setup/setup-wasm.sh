#!/bin/bash
set -ex

scriptdir=$(dirname $0)

if [ -n "$BASE_IMAGE" ]; then 
	# install prequisites
	apt-get -qq update
	apt-get -qq install python nodejs cmake default-jre

	# install emsdk
	git clone https://github.com/juj/emsdk.git /opt/emscripten-sdk
	pushd /opt/emscripten-sdk
	./emsdk install sdk-${EMSDK_VERSION}-64bit
	./emsdk activate sdk-${EMSDK_VERSION}-64bit
	popd

	# cleanup
	rm -rf /opt/emscripten-sdk/.git
	
	# build the gallery example for testing valid emsdk version
	mkdir /tmp/build-test
	pushd /tmp/build-test
	source /opt/emscripten-sdk/emsdk_env.sh
	git clone https://code.qt.io/qt/qtquickcontrols2.git --branch v$QT_VER
	/opt/qt/$QT_VER/$PLATFORM/bin/qmake qtquickcontrols2/examples/quickcontrols2/gallery
	make
	popd
	rm -rf /tmp/build-test
fi
