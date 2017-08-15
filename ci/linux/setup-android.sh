#!/bin/bash
set -e

scriptdir=$(dirname $0)

# common setup
export SUDO=sudo
$scriptdir/setup-common.sh

# install android deps
sudo apt-get -qq install --no-install-recommends openjdk-8-jdk unzip

# android skd/ndk
curl -Lo /tmp/android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
mkdir $HOME/android
unzip -qq /tmp/android-sdk.zip -d $HOME/android/sdk/
rm -f /tmp/android-sdk.zip
echo y | $HOME/android/sdk/tools/bin/sdkmanager --update
echo y | $HOME/android/sdk/tools/bin/sdkmanager "platform-tools" "platforms;android-26" "build-tools" "extras;google;m2repository" "extras;android;m2repository" "ndk-bundle"

find "$HOME/android" -name apksigner

sudo rm -rf /tmp/*
