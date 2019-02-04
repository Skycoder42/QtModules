#!/bin/bash
set -e

scriptdir=$(dirname $0)

# create installer script
qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo "qtVersion = \"$qtvid\";" > $scriptdir/qt-updater-script.qs
echo "prefix = \"qt.qt5.\";" >> $scriptdir/qt-updater-script.qs
echo "platform = \"$PLATFORM\";" >> $scriptdir/qt-updater-script.qs
echo "extraMods = [];" >> $scriptdir/qt-updater-script.qs
for mod in $EXTRA_MODULES; do
	echo "extraMods.push(\"$mod\");" >> $scriptdir/qt-updater-script.qs
done
cat $scriptdir/qt-updater-script-base.qs >> $scriptdir/qt-updater-script.qs

# update Qt
if ! /opt/qt/MaintenanceTool -platform minimal --script $scriptdir/qt-updater-script.qs --addTempRepository https://install.skycoder42.de/qtmodules/linux_x64 --verbose &> /tmp/install-log.txt; then
	cat /tmp/install-log.txt
	exit 1
fi

# cleanup
rm -rf /opt/qt/Examples
rm -rf /opt/qt/Docs
rm -rf /opt/qt/Tools/QtCreator
