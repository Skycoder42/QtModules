#!/bin/bash
set -e

scriptdir=$(dirname $0)

# brew installs
brew update
brew tap Skycoder42/qt-modules
brew upgrade coreutils || brew install coreutils
brew upgrade python || brew install python3
brew install make
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
which make
make --version

# install qdep
sudo pip3 install qdep

# clang only -> install qtifw
if [[ $PLATFORM == "clang_64" ]]; then
	export EXTRA_MODULES="qt.tools.ifw.31 $EXTRA_MODULES"
fi

# prepare installer script
qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo "qtVersion = \"$qtvid\";" > $scriptdir/qt-installer-script.qs
echo "prefix = \"qt.qt5.\";" >> $scriptdir/qt-installer-script.qs

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
if [[ -n "$QT_INSTALL_URL" ]]; then
	curl -Lo /tmp/install.tar.xz https://github.com/Skycoder42/QtModules-LTS/releases/download/ios-build-${QT_VER}/ios_${QT_VER}_setup.tar.xz
	tar xf /tmp/install.tar.xz -C /opt
else
	curl -Lo /tmp/installer.dmg https://download.qt.io/official_releases/online_installers/qt-unified-mac-x64-online.dmg
	hdiutil attach /tmp/installer.dmg
	export QT_QPA_PLATFORM=minimal
	sudo /Volumes/qt-unified-mac-*/qt-unified-mac-*/Contents/MacOS/qt-unified-mac-* --script $scriptdir/qt-installer-script.qs --addRepository https://install.skycoder42.de/qtmodules/mac_x64/ --verbose
fi

# prepare qdep
sudo qdep prfgen --qmake "/opt/qt/$QT_VER/$PLATFORM/bin/qmake"

# cleanup
sudo rm -rf /opt/qt/Examples
sudo rm -rf /opt/qt/Docs
sudo rm -rf /opt/qt/Tools/QtCreator
