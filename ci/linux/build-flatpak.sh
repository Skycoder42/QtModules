#!/bin/bash
set -ex

export XZ_OPT=-9

scriptdir=$(dirname $0)

if [[ -z "$NO_FLATDEP" ]]; then
	flat_dir="${FLATDEP_DIR:-"deployment/flatpak"}"
	"$flat_dir/flatdep.py" "$FLATPAK_MANIFEST"
fi

cd flatpak-build
flatpak-builder build "../$FLATPAK_MANIFEST" --force-clean
mkdir -p ../install
tar cJf ../install/flatpak_build.tar.xz build
