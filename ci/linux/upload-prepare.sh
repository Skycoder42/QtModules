#!/bin/bash
set -e

export XZ_OPT=-9

cd install/opt/qt/$QT_VER

PNAME=$PLATFORM
if [[ $PLATFORM == "static" ]]; then
	export PNAME="${PNAME}_${TRAVIS_OS_NAME}"
fi

tar cJf build_${PNAME}_${QT_VER}.tar.xz $PLATFORM
mv build_${PNAME}_${QT_VER}.tar.xz ../../

if [[ -n "$BUILD_DOC" ]]; then
	cd ../Docs
	tar cJf build_doc_$QT_VER.tar.xz ./*
	mv build_doc_$QT_VER.tar.xz ../../
fi
