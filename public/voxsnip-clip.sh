#!/usr/bin/env bash
# VoxSnip — area screenshot to clipboard
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only
set -u

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=voxsnip-lib.sh
. "${HERE}/voxsnip-lib.sh"

TMPDIR="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/voxsnip.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT
IMG="${TMPDIR}/snip.png"

if ! voxsnip_capture_area "$IMG"; then
  exit 0
fi

if ! voxsnip_copy_image "$IMG"; then
  voxsnip_notify "No clipboard tool found (install wl-clipboard or xclip)."
  exit 1
fi

voxsnip_notify "Screenshot copied to clipboard."
exit 0
