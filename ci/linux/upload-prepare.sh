#!/bin/bash
set -e

export XZ_OPT=-9

cd install/opt/qt/$QT_VER

if [[ $EXCLUDE_PLATFORMS != *"linux"* ]]; then
	tar cJf build_linux_$QT_VER.tar.xz gcc_64
fi

if [[ $EXCLUDE_PLATFORMS != *"android"* ]]; then
	tar cJf build_android_$QT_VER.tar.xz android_armv7 android_x86
fi

cd ../Docs
tar cJf build_doc_$QT_VER.tar.xz ./*

cd ..
find .
