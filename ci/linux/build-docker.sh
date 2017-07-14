#!/bin/bash
set -e

scriptdir=$(dirname $0)

export QMAKE_FLAGS="QMAKE_LFLAGS+=-no-pie $QMAKE_FLAGS"

$scriptdir/build-all.sh
