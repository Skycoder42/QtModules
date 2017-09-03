#!/bin/bash
set -e

tDir=/opt/qt/$QT_VER/static
$SUDO mkdir -p $tDir

if [[ -n "$SUDO" ]]; then
	$SUDO chown -R $USER /opt/qt/$QT_VER/Src
fi
pushd /opt/qt/$QT_VER/Src/

#bug: remove gui from macdeployqt
echo "QT -= gui" >> qttools/src/macdeployqt/macdeployqt/macdeployqt.pro
echo "QT -= gui" >> qttools/src/macdeployqt/macchangeqt/macchangeqt.pro

# generate skip modules
for mod in $(ls -d qt*/ | cut -f1 -d'/'); do
	if [[ "qtbase $STATIC_QT_MODS $STATIC_EXTRA_MODS" != *"$mod"* ]]; then
		skipPart="-skip $mod $skipPart"
	fi
done

# build qt
./configure -prefix $tDir -opensource -confirm-license -release -static -static-runtime -no-use-gold-linker -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets $skipPart
make > /dev/null
$SUDO make install > /dev/null

#build extra modules explicitly
for mod in $STATIC_EXTRA_MODS; do
	pushd $mod
	$tDir/bin/qmake -r
	make > /dev/null
	$SUDO make install > /dev/null
	popd
done

popd
$SUDO rm -rf /opt/qt/$QT_VER/Src
