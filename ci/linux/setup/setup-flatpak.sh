#!/bin/bash
set -e

scriptdir=$(dirname $0)

pacman --noconfirm -Syyu
pacman --noconfirm -S flatpak flatpak-builder qpmx qpmx-qpmsource

export MAKEFLAGS="-j$(nproc)"

flatpak install -y flathub "org.kde.Platform//$QT_VER_MINOR"
flatpak install -y flathub "org.kde.Sdk//$QT_VER_MINOR"

rm -rf /tmp/*
