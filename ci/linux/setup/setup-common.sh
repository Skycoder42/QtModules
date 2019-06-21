#!/bin/bash
set -e

scriptdir=$(dirname $0)

# install build deps
apt-get -qq update
apt-get -qq install --no-install-recommends software-properties-common libgl1-mesa-dev libglib2.0-0 libpulse-dev make g++ git ca-certificates curl xauth libx11-xcb1 libfontconfig1 libdbus-1-3 libpq5 libsecret-1-dev libsystemd-dev python3 python3-pip doxygen doxyqml libssl1.1 $EXTRA_PKG

# install qdep
pip3 install qdep

# create installer script
qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo "qtVersion = \"$qtvid\";" > $scriptdir/qt-installer-script.qs
echo "prefix = \"qt.qt5.\";" >> $scriptdir/qt-installer-script.qs
echo "platform = \"$PLATFORM\";" >> $scriptdir/qt-installer-script.qs
echo "extraMods = [];" >> $scriptdir/qt-installer-script.qs
for mod in $EXTRA_MODULES; do
	echo "extraMods.push(\"$mod\");" >> $scriptdir/qt-installer-script.qs
done
cat $scriptdir/qt-installer-script-base.qs >> $scriptdir/qt-installer-script.qs

# install Qt
curl -Lo /tmp/installer.run https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x /tmp/installer.run
export QT_QPA_PLATFORM=minimal
if ! /tmp/installer.run --script $scriptdir/qt-installer-script.qs --addTempRepository https://install.skycoder42.de/qtmodules/linux_x64 --verbose &> /tmp/install-log.txt; then
	exitCode=$?
	cat /tmp/install-log.txt
	exit $exitCode
fi

# prepare qdep
qdep prfgen --qmake "/opt/qt/$QT_VER/$PLATFORM/bin/qmake"

# cleanup
rm -rf /opt/qt/Examples
rm -rf /opt/qt/Docs
rm -rf /opt/qt/Tools/QtCreator
