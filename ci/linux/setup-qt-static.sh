#!/bin/bash
set -e

tDir=/opt/qt/$QT_VER/static
$SUDO mkdir -p $tDir

$SUDO chown -R $USER /opt/qt/$QT_VER/Src
cd /opt/qt/$QT_VER/Src/

for mod in $(ls -d qt*/ | cut -f1 -d'/'); do
	if [[ "qtbase $STATIC_QT_MODS" != *"$mod"* ]]; then
		skipPart="-skip $mod $skipPart"
	fi
done

./configure -prefix $tDir -opensource -confirm-license -release -static -static-runtime -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets $skipPart
make > /dev/null
$SUDO make install > /dev/null

find $tDir
