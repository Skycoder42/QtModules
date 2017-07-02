#!/bin/bash
# $1 platform
# $2 compiler
set -e

platform=$1
compiler=$2

$(dirname $0)/build-first.sh "$@"

cd build-$platform
make all

export LD_LIBRARY_PATH="$(pwd)/lib:$LD_LIBRARY_PATH"
export QT_QPA_PLATFORM=minimal

cd tests/auto
for test in $(find . -type f -executable -name "tst_*"); do
	$test
done
