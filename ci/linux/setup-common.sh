#!/bin/bash
set -e

scriptdir=$(dirname $0)

# install build deps
apt-get -qq update
apt-get -qq install --no-install-recommends libgl1-mesa-dev libglib2.0-0 libpulse-dev make g++ git ca-certificates curl xauth libx11-xcb1 libfontconfig1 libdbus-1-3 python3 doxygen

# install qpm
curl -Lo /tmp/qpm https://www.qpm.io/download/v0.10.0/linux_386/qpm
install -m 755 /tmp/qpm /usr/local/bin/

# create installer script
qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo qtVersion = \"$qtvid\"\; > $scriptdir/qt-installer-script.qs
echo platform = \"$PLATFORM\"\; >> $scriptdir/qt-installer-script.qs
echo extraMods = []\; >> $scriptdir/qt-installer-script.qs
for mod in $EXTRA_MODULES; do
	echo extraMods.push(\"$mod\")\;
done
cat $scriptdir/qt-installer-script-base.qs >> $scriptdir/qt-installer-script.qs

# DEBUG
cat $scriptdir/qt-installer-script.qs

# install Qt
curl -Lo /tmp/installer.run https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x /tmp/installer.run
QT_QPA_PLATFORM=minimal /tmp/installer.run --script $scriptdir/qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/linux_x64

rm -rf /opt/qt/Examples
rm -rf /opt/qt/Docs
rm -rf /opt/qt/Tools/QtCreator
