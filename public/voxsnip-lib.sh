#!/usr/bin/env bash
# VoxSnip — shared capture helpers
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only

voxsnip_notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="VoxSnip" "VoxSnip" "$1" || true
  fi
}

# Custom shortcuts fire while Alt is still down.
voxsnip_wait_for_hotkey() {
  sleep 0.35
}

voxsnip_copy_image() {
  local file="$1"
  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] && command -v wl-copy >/dev/null 2>&1; then
    wl-copy --type image/png < "$file"
    return $?
  fi
  if command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -t image/png -i "$file"
    return $?
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy --type image/png < "$file"
    return $?
  fi
  return 1
}

voxsnip_copy_text() {
  local text="$1"
  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] && command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$text" | wl-copy
    return $?
  fi
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$text" | xclip -selection clipboard
    return $?
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$text" | wl-copy
    return $?
  fi
  return 1
}

VOXSNIP_SOURCE_IMAGE=""

voxsnip_discard_source() {
  if [[ -n "${VOXSNIP_SOURCE_IMAGE:-}" && -f "$VOXSNIP_SOURCE_IMAGE" ]]; then
    rm -f "$VOXSNIP_SOURCE_IMAGE"
  fi
  VOXSNIP_SOURCE_IMAGE=""
}

# Write a PNG of the user-selected region to $1.
# On GNOME 42+ / Wayland the Shell screenshot D-Bus API is denied, so we use
# the desktop portal. Choose the dashed-rectangle (Selection) mode, then drag.
voxsnip_capture_area() {
  local dest="$1"
  local here portal src

  voxsnip_wait_for_hotkey

  here="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
  portal="${here}/voxsnip-portal.py"
  if [[ ! -f "$portal" ]]; then
    voxsnip_notify "Missing ${portal}"
    return 1
  fi

  if ! src="$(python3 "$portal")"; then
    return 1
  fi
  if [[ ! -s "$src" ]]; then
    return 1
  fi

  VOXSNIP_SOURCE_IMAGE="$src"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  return 0
}
