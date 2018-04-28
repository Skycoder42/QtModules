#!/bin/bash
# $1 Qt Version
# $2 path
# $3 prefix (default = qt.qt5)
set -e

QT_VERSION=$1
QT_VID=$(echo $QT_VERSION | sed -e "s/\\.//g")
MODPATH=$2
PREFIX="${3:-qt.qt5}.${QT_VID}.skycoder42"
QT_VID=qt$QT_VID

tDir=$(mktemp -d)
cd $tDir
mkdir "$PREFIX"
7z a 1.0.0meta.7z "$PREFIX" > /dev/null
checksum=$(sha1sum 1.0.0meta.7z | awk '{ print $1 }')

mkdir -p "$MODPATH/$QT_VID"
cd "$MODPATH/$QT_VID"

for os in linux_x64 windows_x86 mac_x64; do
	case $os in
		linux_x64)
			osName=Linux
			;;
		windows_x86)
			osName=Windows
			;;
		mac_x64)
			osName=macOs
			;;
	esac

	mkdir -p "$os/$PREFIX"
	cd $os
	
	cp "$tDir/1.0.0meta.7z" "$PREFIX/"
	
	set +e
	read -d '' updatesXml <<- EOF
<Updates>
 <ApplicationName>{AnyApplication}</ApplicationName>
 <ApplicationVersion>1.0.0</ApplicationVersion>
 <Checksum>true</Checksum>
 <PackageUpdate>
  <Name>$PREFIX</Name>
  <DisplayName>Skycoder42 Qt $QT_VERSION modules</DisplayName>
  <Description>Contains all my Qt $QT_VERSION modules, for a simple installation.</Description>
  <Version>1.0.0</Version>
  <ReleaseDate>$(date +%Y-%m-%d)</ReleaseDate>
  <Default>true</Default>
  <UpdateFile UncompressedSize="0" OS="Any" CompressedSize="0"/>
  <SHA1>$checksum</SHA1>
 </PackageUpdate>
 <RepositoryUpdate>
  <!--Repository action="add" url="https://install.skycoder42.de/qtmodules/$QT_VID/qtjsonserializer/$os" displayname="Qt $QT_VERSION QtJsonSerializer $osName Repository"/-->
  <!--Repository action="add" url="https://install.skycoder42.de/qtmodules/$QT_VID/qtrestclient/$os" displayname="Qt $QT_VERSION QtRestClient $osName Repository"/-->
  <!--Repository action="add" url="https://install.skycoder42.de/qtmodules/$QT_VID/qtdatasync/$os" displayname="Qt $QT_VERSION QtDataSync $osName Repository"/-->
  <!--Repository action="add" url="https://install.skycoder42.de/qtmodules/$QT_VID/qtmvvm/$os" displayname="Qt $QT_VERSION QtMvvm $osName Repository"/-->
  <!--Repository action="add" url="https://install.skycoder42.de/qtmodules/$QT_VID/qtautoupdater/$os" displayname="Qt $QT_VERSION QtAutoUpdater $osName Repository"/-->
  <!--Repository action="add" url="https://install.skycoder42.de/qtmodules/$QT_VID/qtapngplugin/$os" displayname="Qt $QT_VERSION QtApngPlugin $osName Repository"/-->
 </RepositoryUpdate>
</Updates>
EOF
	set -e
	
	echo "$updatesXml" > Updates.xml
	
	cd ..
done
