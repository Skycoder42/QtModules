#!/bin/bash
set -e

mkdir build-ios
cd build-ios

/opt/qt/5.9.1/ios/bin/qmake -r ../qtjsonserializer.pro
make
make INSTALL_ROOT="$(pwd)/../install" install
