#!/bin/sh

QT_PATH="/opt/qt"
QT_TMP_PATH="/tmp/qt"

apt-get update
apt-get -qq install --no-install-recommends libgl1-mesa-dev libglib2.0-0 libpulse-dev g++ make git ca-certificates curl xauth libx11-xcb1 libfontconfig1 libdbus-1-3

curl -Lo ${QT_TMP_PATH}/qpm https://www.qpm.io/download/v0.10.0/linux_386/qpm && install -m 755 ${QT_TMP_PATH}/qpm /usr/local/bin/
curl -Lo ${QT_TMP_PATH}/installer.run https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x ${QT_TMP_PATH}/installer.run && QT_QPA_PLATFORM=minimal ${QT_TMP_PATH}/installer.run --script ${QT_TMP_PATH}/qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/linux_x64

rm -rf ${QT_PATH}/Examples
rm -rf ${QT_PATH}/Docs
rm -rf ${QT_PATH}/Tools
rm -rf /tmp/*
rm -rf /var/lib/apt/lists/*