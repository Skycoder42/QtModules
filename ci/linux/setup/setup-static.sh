#!/bin/bash
set -e

### compile static Qt
tDir=/opt/qt/$QT_VER/static
$SUDO mkdir -p $tDir
if [[ -n "$SUDO" ]]; then
	$SUDO chown -R $USER /opt/qt/$QT_VER/Src
fi

pushd /opt/qt/$QT_VER/Src/

#bug: remove gui from macdeployqt
echo "QT -= gui" >> qttools/src/macdeployqt/macdeployqt/macdeployqt.pro
echo "QT -= gui" >> qttools/src/macdeployqt/macchangeqt/macchangeqt.pro

#include extra modules explicitly
for mod in $STATIC_EXTRA_MODS; do
	echo -e "[submodule \"${mod}\"]" >> .gitmodules
	echo -e "\tdepends = qtbase" >> .gitmodules
	echo -e "\tpath = ${mod}" >> .gitmodules
	echo -e "\turl = ../${mod}.git" >> .gitmodules
	echo -e "\tbranch = ${QT_VER}" >> .gitmodules
	echo -e "\tstatus = addon" >> .gitmodules
	echo -e "\trepoType = inherited" >> .gitmodules

done

# generate skip modules
for mod in $(ls -d qt*/ | cut -f1 -d'/'); do
	if [[ "qtbase qttools $STATIC_QT_MODS $STATIC_EXTRA_MODS" != *"$mod"* ]]; then
		skipPart="-skip $mod $skipPart"
	fi
done

# build qt (shadowed)
pushd $(mktemp -d)
/opt/qt/$QT_VER/Src/configure -prefix $tDir -opensource -confirm-license -release -static -static-runtime -no-use-gold-linker -no-cups -no-qml-debug -no-opengl -no-egl -no-xinput2 -no-sm -no-icu -nomake examples -nomake tests -accessibility -no-gui -no-widgets $skipPart
make > /dev/null
$SUDO make install > /dev/null
popd

popd
$SUDO rm -rf /opt/qt/$QT_VER/Src #make space for docker
