#!/bin/bash
set -e

# install qpm
curl -Lo /tmp/qpm https://www.qpm.io/download/v0.10.0/darwin_386/qpm
sudo install -m 755 /tmp/qpm /usr/local/bin/

# install Qt
curl -Lo /tmp/installer.dmg https://download.qt.io/official_releases/online_installers/qt-unified-mac-x64-online.dmg
hdiutil attach /tmp/installer.dmg
find /Volumes/qt-unified-mac-x64-3.0.0-online
QT_QPA_PLATFORM=minimal sudo /Volumes/qt-unified-mac-*/qt-unified-mac-*/Contents/MacOS/qt-unified-mac-* --script tests/travis/osx/qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/mac_x64/
