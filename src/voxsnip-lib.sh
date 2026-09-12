#!/usr/bin/env bash
# VoxSnip — shared capture helpers
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only

voxsnip_notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="VoxSnip" "VoxSnip" "$1" || true
  fi
}

# Custom shortcuts fire while Alt is still down. GNOME will not start
# an area picker until the modifier is released.
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

voxsnip_capture_via_shell() {
  local dest="$1"
  command -v gdbus >/dev/null 2>&1 || return 1

  local raw
  if ! raw="$(gdbus call --session \
    --dest org.gnome.Shell.Screenshot \
    --object-path /org/gnome/Shell/Screenshot \
    --method org.gnome.Shell.Screenshot.SelectArea 2>/dev/null)"; then
    return 1
  fi

  local x y w h
  read -r x y w h < <(printf '%s' "$raw" | grep -oE '-?[0-9]+' | head -n 4 | tr '\n' ' ')
  [[ -n "${x:-}" && -n "${y:-}" && -n "${w:-}" && -n "${h:-}" ]] || return 1
  [[ "$w" -gt 0 && "$h" -gt 0 ]] || return 1

  mkdir -p "$(dirname "$dest")"
  rm -f "$dest"

  local shot used
  if ! shot="$(gdbus call --session \
    --dest org.gnome.Shell.Screenshot \
    --object-path /org/gnome/Shell/Screenshot \
    --method org.gnome.Shell.Screenshot.ScreenshotArea \
    "$x" "$y" "$w" "$h" true "$dest" 2>/dev/null)"; then
    return 1
  fi

  if [[ -s "$dest" ]]; then
    return 0
  fi

  used="$(printf '%s' "$shot" | grep -oE "'[^']+'" | tail -n 1 | tr -d "'")"
  if [[ -n "$used" && -s "$used" && "$used" != "$dest" ]]; then
    cp "$used" "$dest"
    return 0
  fi
  return 1
}

# Write a PNG of the user-selected region to $1. Returns 1 if cancelled or failed.
voxsnip_capture_area() {
  local dest="$1"

  voxsnip_wait_for_hotkey

  if voxsnip_capture_via_shell "$dest"; then
    return 0
  fi

  if command -v gnome-screenshot >/dev/null 2>&1; then
    mkdir -p "$(dirname "$dest")"
    rm -f "$dest"
    if gnome-screenshot -a -f "$dest" && [[ -s "$dest" ]]; then
      return 0
    fi
  fi

  return 1
}
