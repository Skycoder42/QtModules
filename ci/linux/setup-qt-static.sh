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

#build modules explicitly
for mod in qtbase $STATIC_QT_MODS; do
	pushd $mod
	if [[ "$mod" == "qtbase" ]]; then
		./configure -prefix $tDir -opensource -confirm-license -release -static -static-runtime -no-use-gold-linker -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets
	else
		$tDir/qmake -r
	fi
	make > /dev/null
	$SUDO make install > /dev/null
	popd
done


for mod in $(ls -d qt*/ | cut -f1 -d'/'); do
	if [[ "qtbase $STATIC_QT_MODS" != *"$mod"* ]]; then
		skipPart="-skip $mod $skipPart"
	fi
done

popd
$SUDO rm -rf /opt/qt/$QT_VER/Src
