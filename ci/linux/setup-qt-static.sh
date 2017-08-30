#!/bin/bash
set -e

if [[ -z "$QT_VER_SHORT" ]]; then
	QT_VER_SHORT=$QT_VER
fi
if [[ -z "$QT_VER_FULL" ]]; then
	QT_VER_FULL=${QT_VER_SHORT}.0
fi

tDir=/opt/qt-static
mkdir -p $tDir

pushd $(mktemp -d)
mkdir src

pushd download
for mod in qtbase $STATIC_QT_MODS; do
	curl -Lo "pkg-$mod.tar.xz" "https://download.qt.io/official_releases/qt/$QT_VER_SHORT/$QT_VER_FULL/submodules/$mod-opensource-src-$QT_VER_FULL.tar.xz"
	tar -xf "pkg-$mod.tar.xz"
	mv "$mod"* ./src/$mod
done
popd
rm -rf download

cd src

pushd qtbase
./qtbase/configure -top-level -prefix $tDir -opensource -confirm-license -release -static -static-runtime -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets $skipPart
popd

make > /dev/null
$SUDO make install > /dev/null

find /tmp/qt-static
