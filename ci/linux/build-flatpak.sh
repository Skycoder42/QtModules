#!/bin/bash
set -e

export XZ_OPT=-9

scriptdir=$(dirname $0)

cd flatpak-build
flatpak-builder build "../$FLATPAK_MANIFEST" --force-clean
tar cJf install/flatpak_build.tar.xz build
