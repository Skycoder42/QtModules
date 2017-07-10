#!/bin/bash
set -e

if [[ $TRAVIS_OS_NAME == "linux" ]]; then
	sudo chown -r $USER ./install
fi

export XZ_OPT=-9

cd install/opt/qt/$QT_VER

if [[ $EXCLUDE_PLATFORMS != *"linux"* ]]; then
	tar cJf build_linux_$QT_VER.tar.xz gcc_64
	mv build_linux_$QT_VER.tar.xz ../../
fi

if [[ $EXCLUDE_PLATFORMS != *"android"* ]]; then
	tar cJf build_android_$QT_VER.tar.xz android_armv7 android_x86
	mv build_android_$QT_VER.tar.xz ../../
fi

cd ../Docs
tar cJf build_doc_$QT_VER.tar.xz ./*
mv build_doc_$QT_VER.tar.xz ../../
