#!/bin/bash
set -e

scriptdir=$(dirname $0)

# install android deps
apt-get -qq install --no-install-recommends openjdk-8-jdk unzip

# android skd/ndk
curl -Lo /tmp/android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
mkdir $HOME/android
unzip -qq /tmp/android-sdk.zip -d $HOME/android/sdk/
rm -f /tmp/android-sdk.zip

echo y | $HOME/android/sdk/tools/bin/sdkmanager --update > /dev/null
for package in "platform-tools" "platforms;android-28" "build-tools;28.0.2" "ndk-bundle"; do
	echo install android $package
	echo y | $HOME/android/sdk/tools/bin/sdkmanager "$package" > /dev/null
done

## ndk gcc bug workaround
#curl -Lo /tmp/android-ndk.zip https://dl.google.com/android/repository/android-ndk-r17c-linux-x86_64.zip
#unzip -qq /tmp/android-ndk.zip -d $HOME/android/sdk/
#mv $HOME/android/sdk/android-ndk-r17c $HOME/android/sdk/ndk-bundle
#rm -f /tmp/android-ndk.zip
