#!/bin/bash
# $1 Module Name
# $2 branch
# $3 mode
# $4 distro
set -e

module=$1
branch=$2
mode=$3
distro=$4

if [[ "$mode" == "standard" ]]; then
	name=${module,,}
	name=libqt5${name:2}
fi
if [[ "$mode" == "opt" ]]; then
	name=${module,,}
fi

pwDir=$(mktemp -d)
home=$(dirname $(readlink -f $0))

pushd "$pwDir"
wget "https://github.com/Skycoder42/$module/archive/$branch.tar.gz"

bzr dh-make "$name" "$branch" "$branch.tar.gz"

pushd "$name"
rm -rf "debian"
cp -r "$home/$mode/$name/debian" debian

sed -i -e "s/#{distro}/$distro/g" debian/changelog

bzr add debian/source/* debian/*
bzr commit -m "setup"

export $(cat /etc/*-release | grep DISTRIB_CODENAME)
if [[ "$DISTRIB_CODENAME" == "$distro" ]]; then
	bzr builddeb -- -uc -us
else
	echo skipping local build, different distro
fi

echo
echo
read -p "please prepare gpg key for pbuild" trash

rm -rf ../build-area
bzr builddeb -S
popd

pushd build-area
pbuilder-dist "$distro" build *.dsc

read -p "publish on launchpad? [y/N] " publish

if [[ "$publish" == "y" ]]; then
	ppa="qt-modules"
	if [[ "$mode" == "opt" ]]; then
		ppa="$ppa-opt"
	fi
	dput "ppa:skycoder42/$ppa" *.changes
fi
popd

popd
rm -rf "$tDir"
