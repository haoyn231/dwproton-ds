#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Rebuild modules in an existing, configured Proton build tree.
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /absolute/path/to/configured-build" >&2
    exit 2
fi
build_dir=$(realpath -- "$1")
source_dir=$(dirname -- "$build_dir")
for arch in i386 x86_64; do
    if [[ ! -f "$build_dir/obj-wine-$arch/Makefile" ]]; then
        echo "Missing configured Wine build: $build_dir/obj-wine-$arch" >&2
        exit 1
    fi
done
podman run --rm \
    -v "$source_dir:$source_dir" \
    -w "$build_dir" \
    registry.gitlab.steamos.cloud/proton/steamrt4/sdk/x86_64:4.0.20260714.251823-0 \
    sh -eu -c '
        for arch in i386 x86_64; do
            for module in hidclass.sys winebus.sys mmdevapi setupapi winepulse.drv xaudio2_7; do
                make -j6 -C "obj-wine-$arch/dlls/$module"
            done
        done
    '
