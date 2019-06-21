#!/bin/bash
set -e

scriptdir=$(dirname $0)

# install android deps
apt-get -qq install --no-install-recommends openjdk-8-jdk unzip

# android skd/ndk
SDK_SHASUM=92ffee5a1d98d856634e8b71132e8a95d96c83a63fde1099be3d86df3106def9
curl -Lo /tmp/android-sdk.zip "https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
echo "$SDK_SHASUM /tmp/android-sdk.zip" | sha256sum --check -
mkdir $HOME/android
unzip -qq /tmp/android-sdk.zip -d $HOME/android/sdk/
rm -f /tmp/android-sdk.zip

echo y | $HOME/android/sdk/tools/bin/sdkmanager --update > /dev/null
for package in "platform-tools" "platforms;android-28" "build-tools;28.0.3"; do
	echo "installing android $package"
	echo y | $HOME/android/sdk/tools/bin/sdkmanager "$package" > /dev/null
done

#NDK_REVISION=r19c
if [ -n "$NDK_REVISION" ]; then
	echo "installing android ndk-bundle $NDK_REVISION"
	NDK_SHASUM=fd94d0be6017c6acbd193eb95e09cf4b6f61b834
	curl -Lo /tmp/android-ndk.zip "https://dl.google.com/android/repository/android-ndk-$NDK_REVISION-linux-x86_64.zip"
	echo "$NDK_SHASUM /tmp/android-ndk.zip" | sha1sum --check -
	unzip -qq /tmp/android-ndk.zip -d $HOME/android/sdk/
	mv $HOME/android/sdk/android-ndk-$NDK_REVISION $HOME/android/sdk/ndk-bundle
else
	echo "installing android ndk-bundle"
	echo y | $HOME/android/sdk/tools/bin/sdkmanager "ndk-bundle" > /dev/null
fi
