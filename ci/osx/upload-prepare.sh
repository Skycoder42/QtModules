#!/bin/bash
set -e

export XZ_OPT=-9

cd install/opt/qt/$QT_VER
tar cJf build_osx_$QT_VER.tar.xz clang_64 ios
mv build_osx_$QT_VER.tar.xz ../../
