#!/bin/bash
set -e

tDir=/opt/qt-static
mkdir -p $tDir

$SUDO chown -R $USER /opt/qt/$QT_VER/Src
cd /opt/qt/$QT_VER/Src/

for mod in qtbase $STATIC_QT_MODS; do
	pushd $mod
	if [[ "$mod" == "qtbase" ]]; then
		./configure -prefix $tDir -opensource -confirm-license -release -static -static-runtime -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets
	else
		../qtbase/bin/qmake -r
	fi
	
	make > /dev/null
	$SUDO make install > /dev/null
	
	popd
done

find /tmp/qt-static
