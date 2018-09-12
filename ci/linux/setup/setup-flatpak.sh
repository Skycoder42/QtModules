#!/bin/bash
set -e

scriptdir=$(dirname $0)

sudo add-apt-repository -y ppa:alexlarsson/flatpak
sudo apt-get -qq update
sudo apt-get -qq install flatpak flatpak-builder

export MAKEFLAGS="-j$(nproc)"

flatpak --version
flatpak install -y flathub "org.kde.Platform//$QT_VER_MINOR"
flatpak install -y flathub "org.kde.Sdk//$QT_VER_MINOR"

rm -rf /tmp/*
