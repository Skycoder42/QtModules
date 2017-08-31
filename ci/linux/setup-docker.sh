#!/bin/bash
set -e

scriptdir=$(dirname $0)

export MAKEFLAGS="-j$(nproc)"

# common setup
$scriptdir/setup-common.sh

# install gcc and linuxdeployqt deps
apt-get -qq install --no-install-recommends patchelf libjasper1 libxi6 libsm6 libpq5
rm -f /opt/qt/$QT_VER/$PLATFORM/plugins/sqldrivers/libqsqlmysql*

# install linuxdeployqt
pdir=$(pwd)

cd $(mktemp -d)

mkdir build
git clone https://github.com/probonopd/linuxdeployqt.git --branch continuous

cd linuxdeployqt

rm -rf tests
mkdir tests
echo 'TEMPLATE = aux' > tests/tests.pro

echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licudata' >> tools/linuxdeployqt/linuxdeployqt.pro
echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licui18n' >> tools/linuxdeployqt/linuxdeployqt.pro
echo 'LIBS += -L$$[QT_INSTALL_LIBS] -licuuc' >> tools/linuxdeployqt/linuxdeployqt.pro

cd ../build

/opt/qt/$QT_VER/$PLATFORM/bin/qmake -r ../linuxdeployqt/linuxdeployqt.pro
make
make install

cd "$pdir"

rm -rf /tmp/*
