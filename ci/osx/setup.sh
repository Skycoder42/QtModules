#!/bin/bash
set -e

scriptdir=$(dirname $0)

# python
brew update
brew tap Skycoder42/qt-modules
brew upgrade coreutils || brew install coreutils
brew upgrade python || brew install python3
brew install qpmx qpm $EXTRA_PKG
brew install --with-default-names make

# clang only -> install qtifw
if [[ $PLATFORM == "clang_64" ]]; then
	export EXTRA_MODULES="qt.tools.ifw.30 $EXTRA_MODULES"
fi

# prepare installer script
qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo "qtVersion = \"$qtvid\";" > $scriptdir/qt-installer-script.qs

if [[ "$IS_LTS" == "true" ]]; then
	echo "prefix = \"qt.\";" >> $scriptdir/qt-installer-script.qs
else
	echo "prefix = \"qt.qt5.\";" >> $scriptdir/qt-installer-script.qs
fi

if [[ "$PLATFORM" == "static" ]]; then
	echo "platform = \"src\";" >> $scriptdir/qt-installer-script.qs
else
	echo "platform = \"$PLATFORM\";" >> $scriptdir/qt-installer-script.qs
fi

echo "extraMods = [];" >> $scriptdir/qt-installer-script.qs
for mod in $EXTRA_MODULES; do
	echo "extraMods.push(\"$mod\");" >> $scriptdir/qt-installer-script.qs
done

cat $scriptdir/qt-installer-script-base.qs >> $scriptdir/qt-installer-script.qs

# install Qt
curl -Lo /tmp/installer.dmg https://download.qt.io/official_releases/online_installers/qt-unified-mac-x64-online.dmg
hdiutil attach /tmp/installer.dmg
export QT_QPA_PLATFORM=minimal
if ! sudo /Volumes/qt-unified-mac-*/qt-unified-mac-*/Contents/MacOS/qt-unified-mac-* --script $scriptdir/qt-installer-script.qs --addTempRepository https://install.skycoder42.de/qtmodules/mac_x64/ --verbose &> /tmp/install-log.txt; then
	exitCode=$?
	cat /tmp/install-log.txt
	exit $exitCode
fi

sudo rm -rf /opt/qt/Examples
sudo rm -rf /opt/qt/Docs
sudo rm -rf /opt/qt/Tools/QtCreator

if [[ "$PLATFORM" == "static" ]]; then
	export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
	export SUDO=sudo #because of symlink
	$scriptdir/setup-static.sh
fi
