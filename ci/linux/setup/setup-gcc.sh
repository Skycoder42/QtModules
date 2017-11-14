#!/bin/bash
set -e

scriptdir=$(dirname $0)

## linuxdeployqt setup
export MAKEFLAGS="-j$(nproc)"
apt-get -qq install --no-install-recommends patchelf libjasper1 libxi6 libsm6 libpq5
rm -f /opt/qt/$QT_VER/$PLATFORM/plugins/sqldrivers/libqsqlmysql*

pushd $(mktemp -d)

git clone https://github.com/probonopd/linuxdeployqt.git --branch continuous

pushd linuxdeployqt
echo 'TEMPLATE = aux' > tests/tests.pro
echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licudata' >> tools/linuxdeployqt/linuxdeployqt.pro
echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licui18n' >> tools/linuxdeployqt/linuxdeployqt.pro
echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licuuc' >> tools/linuxdeployqt/linuxdeployqt.pro
popd

mkdir build
pushd build
/opt/qt/$QT_VER/$PLATFORM/bin/qmake -r ../linuxdeployqt/linuxdeployqt.pro
make
make install
popd

popd
