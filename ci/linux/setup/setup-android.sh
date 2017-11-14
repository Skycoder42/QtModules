#!/bin/bash
set -e

scriptdir=$(dirname $0)

# install android deps
apt-get -qq install --no-install-recommends openjdk-8-jdk unzip

# android skd/ndk
curl -Lo /tmp/android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
mkdir $HOME/android
unzip -qq /tmp/android-sdk.zip -d $HOME/android/sdk/
rm -f /tmp/android-sdk.zip
echo y | $HOME/android/sdk/tools/bin/sdkmanager --update > /dev/null
for package in "platform-tools" "platforms;android-26" "build-tools;26.0.2" "ndk-bundle"; do
	echo install android $package
	echo y | $HOME/android/sdk/tools/bin/sdkmanager "$package" > /dev/null
done
