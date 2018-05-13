#!/bin/bash
set -e

export XZ_OPT=-9

cd install/opt/qt/$QT_VER

if [[ $PLATFORM == "static" ]]; then
	export PLATFORM="static_${TRAVIS_OS_NAME}"
	mv static "$PLATFORM"
fi

tar cJf build_${PLATFORM}_${QT_VER}.tar.xz $PLATFORM
mv build_${PLATFORM}_${QT_VER}.tar.xz ../../../

if [[ -n "$BUILD_DOC" ]]; then
	cd ../Docs
	tar cJf build_doc_$QT_VER.tar.xz ./*
	mv build_doc_$QT_VER.tar.xz ../../../
fi

if [[ -n "$BUILD_EXAMPLES" ]]; then
	cd ../Examples
	tar cJf build_examples_$QT_VER.tar.xz ./*
	mv build_examples_$QT_VER.tar.xz ../../../
fi
