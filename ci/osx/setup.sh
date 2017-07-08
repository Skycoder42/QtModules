#!/bin/bash
set -e

scriptdir=$(dirname $0)

# python
brew install python3

# install qpm
curl -Lo /tmp/qpm https://storage.googleapis.com/www.qpm.io/download/latest/darwin_386/qpm
sudo install -m 755 /tmp/qpm /usr/local/bin/

# prepare installer script
function test_include {
	if [[ $EXCLUDE_PLATFORMS != *"$1"* ]]; then
		echo true
	else
		echo false
	fi
}

qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo pfMac = \"$(test_include mac)\" > $scriptdir/qt-installer-script.qs
echo pfIos = \"$(test_include ios)\" >> $scriptdir/qt-installer-script.qs
echo qtVersion = \"$qtvid\" >> $scriptdir/qt-installer-script.qs
cat $scriptdir/qt-installer-script-base.qs >> $scriptdir/qt-installer-script.qs

# install Qt
curl -Lo /tmp/installer.dmg https://download.qt.io/official_releases/online_installers/qt-unified-mac-x64-online.dmg
hdiutil attach /tmp/installer.dmg
find /Volumes/qt-unified-mac-x64-3.0.0-online
QT_QPA_PLATFORM=minimal sudo /Volumes/qt-unified-mac-*/qt-unified-mac-*/Contents/MacOS/qt-unified-mac-* --script $scriptdir/qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/mac_x64/
