#!/usr/bin/env bash
# VoxSnip — extract text from a selected screen area (Tesseract OCR)
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only
set -u

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=voxsnip-lib.sh
. "${HERE}/voxsnip-lib.sh"

CONFIG_FILE="${HOME}/.config/voxsnip/langs.conf"
DEFAULT_LANGS="eng"

read_langs() {
  local langs=""
  if [[ -f "$CONFIG_FILE" ]]; then
    langs="$(
      grep -vE '^[[:space:]]*(#|$)' "$CONFIG_FILE" 2>/dev/null \
        | head -n 1 \
        | tr -d '[:space:]'
    )"
  fi
  if [[ -z "$langs" ]]; then
    langs="$DEFAULT_LANGS"
  fi
  printf '%s' "$langs"
}

if ! command -v tesseract >/dev/null 2>&1; then
  voxsnip_notify "tesseract is not installed."
  exit 1
fi

LANGS="$(read_langs)"
TMPDIR="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/voxsnip.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT
IMG="${TMPDIR}/snip.png"
OUT="${TMPDIR}/ocr"

if ! voxsnip_capture_area "$IMG"; then
  exit 0
fi

if ! tesseract "$IMG" "$OUT" -l "$LANGS" >/dev/null 2>&1; then
  voxsnip_notify "OCR failed. Check languages in ~/.config/voxsnip/langs.conf (${LANGS})."
  exit 1
fi

if [[ ! -f "${OUT}.txt" ]]; then
  voxsnip_notify "OCR produced no output."
  exit 1
fi

TEXT="$(cat "${OUT}.txt")"
TEXT="${TEXT%"${TEXT##*[![:space:]]}"}"

if [[ -z "$TEXT" ]]; then
  voxsnip_notify "No text found in the selected area."
  exit 0
fi

if ! voxsnip_copy_text "$TEXT"; then
  voxsnip_notify "No clipboard tool found (install wl-clipboard or xclip)."
  exit 1
fi

voxsnip_notify "Text extracted and copied to clipboard."
exit 0
