#!/usr/bin/env bash
# VoxSnip — remove user scripts, config, and GNOME shortcuts
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only
set -u

readonly BIN_DIR="${HOME}/.local/bin"
readonly CONFIG_DIR="${HOME}/.config/voxsnip"
readonly EXTENSION_UUID="voxsnip@voxonlabs.com"
readonly EXTENSION_DIR="${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}"
readonly NAMES=("VoxSnip Screenshot" "VoxSnip Text Extractor")

info() { printf '==> %s\n' "$*"; }
ok()   { printf '==> %s\n' "$*"; }

remove_file() {
  local path="$1"
  if [[ -e "$path" ]]; then
    rm -f "$path"
    info "Removed ${path}"
  fi
}

gsettings_paths() {
  local raw
  raw="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true)"
  printf '%s' "$raw" | grep -oE '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom[0-9]+/' || true
}

write_keybinding_list() {
  local -a paths=("$@")
  local list="["
  local first=1
  local p
  for p in "${paths[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ $first -eq 1 ]]; then
      list+="'${p}'"
      first=0
    else
      list+=", '${p}'"
    fi
  done
  list+="]"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$list"
}

remove_shortcuts() {
  if ! command -v gsettings >/dev/null 2>&1; then
    return 0
  fi
  if ! gsettings list-keys org.gnome.settings-daemon.plugins.media-keys >/dev/null 2>&1; then
    return 0
  fi

  local path name keep
  local -a remaining=()
  local removed=0

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    name="$(gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${path}" name 2>/dev/null || true)"
    name="${name#\'}"
    name="${name%\'}"
    keep=1
    local want
    for want in "${NAMES[@]}"; do
      if [[ "$name" == "$want" ]]; then
        keep=0
        break
      fi
    done
    if [[ $keep -eq 1 ]]; then
      remaining+=("$path")
    else
      gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${path}" name 2>/dev/null || true
      gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${path}" command 2>/dev/null || true
      gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${path}" binding 2>/dev/null || true
      removed=$((removed + 1))
    fi
  done <<< "$(gsettings_paths)"

  write_keybinding_list "${remaining[@]}"
  if [[ $removed -gt 0 ]]; then
    info "Removed ${removed} GNOME shortcut(s)."
  fi
}

remove_shell_companion() {
  if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions disable "$EXTENSION_UUID" >/dev/null 2>&1 || true
  fi

  if command -v gsettings >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    local current updated
    current="$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || printf '[]')"
    updated="$(python3 - "$current" "$EXTENSION_UUID" <<'PY'
import ast
import sys

raw, uuid = sys.argv[1:]
if raw.startswith("@as "):
    raw = raw[4:]
try:
    enabled = [item for item in ast.literal_eval(raw) if item != uuid]
except (SyntaxError, ValueError, TypeError):
    enabled = []
print(repr(enabled))
PY
    )"
    gsettings set org.gnome.shell enabled-extensions "$updated" 2>/dev/null || true
  fi

  if [[ -d "$EXTENSION_DIR" ]]; then
    rm -rf "$EXTENSION_DIR"
    info "Removed ${EXTENSION_DIR}"
  fi
}

main() {
  info "Uninstalling VoxSnip user files..."
  remove_file "${BIN_DIR}/voxsnip-clip.sh"
  remove_file "${BIN_DIR}/voxsnip-text.sh"
  remove_file "${BIN_DIR}/voxsnip-lib.sh"
  remove_file "${BIN_DIR}/voxsnip-portal.py"
  remove_file "${BIN_DIR}/voxsnip-uninstall.sh"
  if [[ -d "$CONFIG_DIR" ]]; then
    rm -rf "$CONFIG_DIR"
    info "Removed ${CONFIG_DIR}"
  fi
  remove_shell_companion
  remove_shortcuts
  ok "VoxSnip user files removed. System packages were left installed."
}

main "$@"
