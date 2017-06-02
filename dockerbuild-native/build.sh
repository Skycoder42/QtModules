#!/bin/sh
set -e

apt-get update
apt-get -qq install --no-install-recommends software-properties-common
add-apt-repository ppa:beineri/opt-qt59-xenial
apt-get update

apt-get -qq install --no-install-recommends packaging-dev qt59-meta-full libgl1-mesa-dev libglib2.0-0 libpulse-dev g++ make git ca-certificates curl xauth libx11-xcb1 libfontconfig1 libdbus-1-3
apt-get -qq purge --auto-remove software-properties-common

curl -Lo /tmp/qpm https://www.qpm.io/download/v0.10.0/linux_386/qpm && install -m 755 /tmp/qpm /usr/local/bin/

rm -rf /tmp/*
rm -rf /var/lib/apt/lists/*