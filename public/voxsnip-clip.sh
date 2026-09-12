#!/usr/bin/env bash
# VoxSnip — area screenshot to clipboard
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only
set -u

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="VoxSnip" "VoxSnip" "$1" || true
  fi
}

if ! command -v gnome-screenshot >/dev/null 2>&1; then
  notify "gnome-screenshot is not installed."
  exit 1
fi

if gnome-screenshot -a -c; then
  notify "Screenshot copied to clipboard."
  exit 0
fi

# User cancelled the selection or the capture failed.
exit 0
