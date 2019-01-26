#!/bin/bash
set -e

export XZ_OPT=-9

cd install/opt/qt/$QT_VER

if [[ $PLATFORM == "static" ]]; then
	export PLATFORM="static_${TRAVIS_OS_NAME}"
	mv static "$PLATFORM"
fi

tar cJf ${TARGET_NAME}_${PLATFORM}_${QT_VER}.tar.xz $PLATFORM
mv ${TARGET_NAME}_${PLATFORM}_${QT_VER}.tar.xz ../../../

if [[ -n "$BUILD_DOC" ]]; then
	cd ../Docs
	tar cJf ${TARGET_NAME}_doc_$QT_VER.tar.xz ./*
	mv ${TARGET_NAME}_doc_$QT_VER.tar.xz ../../../
fi

if [[ -n "$BUILD_EXAMPLES" ]]; then
	cd ../Examples
	tar cJf ${TARGET_NAME}_examples_$QT_VER.tar.xz ./*
	mv ${TARGET_NAME}_examples_$QT_VER.tar.xz ../../../
fi
