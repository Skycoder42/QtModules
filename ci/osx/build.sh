#!/bin/bash
set -e

export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"

./tests/travis/osx/build-clang.sh
./tests/travis/osx/build-ios.sh
