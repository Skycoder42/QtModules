#!/bin/bash
set -e

mkdir build-clang
cd build-clang

/opt/qt/5.9.1/clang_64/bin/qmake -r ../qtjsonserializer.pro
make all

export LD_LIBRARY_PATH="$(pwd)/lib:$LD_LIBRARY_PATH"

cd tests/auto
for test in $(find . -type f -executable -name "tst_*"); do
	QT_QPA_PLATFORM=minimal $test
done

cd ../..
make INSTALL_ROOT="$(pwd)/../install" install
