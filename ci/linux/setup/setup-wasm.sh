#!/bin/bash
set -ex

scriptdir=$(dirname $0)

export MAKEFLAGS="-j$(nproc)"

# add ppas
apt-get -qq update
apt-get -qq install software-properties-common
add-apt-repository -y ppa:skycoder42/qt-modules

# install prequisites
apt-get -qq update
apt-get -qq install python nodejs cmake default-jre git make ca-certificates curl python3 python3-pip doxygen doxyqml qpmx $EXTRA_PKG

# install qpm
curl -Lo /tmp/qpm https://www.qpm.io/download/v0.11.0/linux_386/qpm
install -m 755 /tmp/qpm /usr/local/bin/

# install emsdk
git clone https://github.com/juj/emsdk.git /opt/emscripten-sdk
pushd /opt/emscripten-sdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
popd

# build Qt for wasm
QT_BRANCH=v$QT_VER
PREFIX=/opt/qt/$QT_VER/$PLATFORM
QT_MODS="qtbase,qtwebsockets,qtdeclarative,qtremoteobjects,qtimageformats,qtsvg,qtquickcontrols2,qtgraphicaleffects,qtscxml,qtnetworkauth,qttranslations,qtxmlpatterns"

tdir=$(mktemp -d)
pushd $tdir
git clone https://code.qt.io/qt/qt5.git ./src --branch $QT_BRANCH
pushd src
./init-repository --module-subset="$QT_MODS"
popd
mkdir build
pushd build
../src/configure -xplatform wasm-emscripten -opensource -confirm-license -make libs -make tools -prefix "$PREFIX"
make > /dev/null
make install
cp config.summary $PREFIX/config.summary
popd
popd

rm -rf /opt/emscripten-sdk/.git
