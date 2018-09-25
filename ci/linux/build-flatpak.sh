#!/bin/bash
set -e

export XZ_OPT=-9

scriptdir=$(dirname $0)

FLATDEP_DIR="${FLATDEP_DIR:-"deployment/flatpak"}"
if [ -f "$FLATDEP_DIR/flatdep.py" ]; then
	"$FLATDEP_DIR/flatdep.py" "$FLATPAK_MANIFEST"
fi

cd flatpak-build
flatpak-builder build "../$FLATPAK_MANIFEST" --force-clean
mkdir -p ../install
tar cJf ../install/flatpak_build.tar.xz build
