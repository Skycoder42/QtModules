#!/bin/bash
# $1 Qt Version
# $2 Module Name
# $3 Version
# $4 exclude mods
# $5 pkg version
# $6 repository
set -e

qtVer=$1
pkgVer=$5
if [[ -z "$pkgVer" ]]; then
	pkgVer=$3
fi
repoPath=qt$(echo $qtVer | sed -e "s/\\.//g")/$(echo "${2,,}")
echo Installing into $repoPath

tDir=$(mktemp -d)
pushd $tDir

git clone https://github.com/Skycoder42/QtModules.git
mkdir src
cd src

../QtModules/deploy/unpack.sh "$@"
./repogen.sh "$qtVer" "$pkgVer"

basePath=/var/www/installers/qtmodules/$repoPath
if [[ -d "$basePath" ]]; then
	mv "$basePath" "$basePath.old"
fi
mkdir -p "$basePath"
cp -r ./repositories/* "$basePath/"

popd
rm -rf $tDir
