#!/bin/bash
set -e

scriptdir=$(dirname $0)

# install build deps
apt-get -qq update
apt-get -qq install --no-install-recommends libgl1-mesa-dev libglib2.0-0 libpulse-dev make g++ git ca-certificates curl xauth libx11-xcb1 libfontconfig1 libdbus-1-3 python3 doxygen openjdk-8-jdk unzip patchelf

# install qpm
curl -Lo /tmp/qpm https://www.qpm.io/download/v0.10.0/linux_386/qpm
install -m 755 /tmp/qpm /usr/local/bin/

# prepare installer script
function test_include {
	if [[ $EXCLUDE_PLATFORMS != *"$1"* ]]; then
		echo true
	else
		echo false
	fi
}

qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo pfLinux = \"$(test_include linux)\" > $scriptdir/qt-installer-script.qs
echo pfAndroid = \"$(test_include android)\" >> $scriptdir/qt-installer-script.qs
echo qtVersion = \"$qtvid\" >> $scriptdir/qt-installer-script.qs
cat $scriptdir/qt-installer-script-base.qs >> $scriptdir/qt-installer-script.qs

# install Qt
curl -Lo /tmp/installer.run https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x /tmp/installer.run
QT_QPA_PLATFORM=minimal /tmp/installer.run --script $scriptdir/qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/linux_x64

# required to make linuxdeployqt work
apt-get -qq install --no-install-recommends libjasper1 libsm6 libpq5
rm -f /opt/qt/$QT_VER/gcc_64/plugins/sqldrivers/libqsqlmysql.so

# install linuxdeployqt
pdir=$(pwd)

cd $(mktemp -d)

mkdir build
git clone https://github.com/probonopd/linuxdeployqt.git

cd linuxdeployqt

rm -rf tests
mkdir tests
echo 'TEMPLATE = aux' > tests/tests.pro

echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licudata' >> tools/linuxdeployqt/linuxdeployqt.pro
echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licui18n' >> tools/linuxdeployqt/linuxdeployqt.pro
echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licuuc' >> tools/linuxdeployqt/linuxdeployqt.pro

cd ../build

/opt/qt/$QT_VER/gcc_64/bin/qmake -r ../linuxdeployqt/linuxdeployqt.pro
make
make install

cd "$pdir"

# install android deps
if [[ $EXCLUDE_PLATFORMS != *"android"* ]]; then
	# android skd/ndk
	curl -Lo /tmp/android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
	mkdir $HOME/android
	unzip -qq /tmp/android-sdk.zip -d $HOME/android/sdk/
	echo y | $HOME/android/sdk/tools/bin/sdkmanager --update
	echo y | $HOME/android/sdk/tools/bin/sdkmanager "platform-tools" "platforms;android-26" "build-tools;26.0.0" "extras;google;m2repository" "extras;android;m2repository" "ndk-bundle"
fi

rm -rf /opt/qt/Examples
rm -rf /opt/qt/Docs
rm -rf /opt/qt/Tools/QtCreator
rm -rf /tmp/*
rm -rf /var/lib/apt/lists/*
