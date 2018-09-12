#!/bin/bash
set -e

scriptdir=$(dirname $0)

cd flatpak-build
flatpak-builder build "../$FLATPAK_MANIFEST" --force-clean --repo=repo
