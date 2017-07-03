#!/bin/bash
# $1 build platform
set -e

platform=$1

mkdir build-doc
cd build-doc

/opt/qt/$QT_VER/$platform/bin/qmake -r ../doc/doc.pro
make doxygen
make INSTALL_ROOT="$(pwd)/../install" install
