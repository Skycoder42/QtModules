#!/bin/bash
source /opt/qt59/bin/qt59-env.sh
set -e

which qmake

mkdir build
cd build

qmake -r ../qtjsonserializer.pro
make -j$(nproc) all

export LD_LIBRARY_PATH="$(pwd)/lib:$LD_LIBRARY_PATH"

cd tests/auto
for test in $(find . -type f -executable -name "tst_*"); do
	QT_QPA_PLATFORM=minimal $test
done
