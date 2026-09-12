#!/usr/bin/env bash
# VoxSnip — extract text from a selected screen area (Tesseract OCR)
# VoxonLabs
set -u

CONFIG_FILE="${HOME}/.config/voxsnip/langs.conf"
DEFAULT_LANGS="eng"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="VoxSnip" "VoxSnip" "$1" || true
  fi
}

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

copy_to_clipboard() {
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

for cmd in gnome-screenshot tesseract; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    notify "${cmd} is not installed."
    exit 1
  fi
done

LANGS="$(read_langs)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

IMG="${TMPDIR}/snip.png"
OUT="${TMPDIR}/ocr"

if ! gnome-screenshot -a -f "$IMG"; then
  exit 0
fi

if [[ ! -s "$IMG" ]]; then
  exit 0
fi

if ! tesseract "$IMG" "$OUT" -l "$LANGS" >/dev/null 2>&1; then
  notify "OCR failed. Check languages in ~/.config/voxsnip/langs.conf (${LANGS})."
  exit 1
fi

if [[ ! -f "${OUT}.txt" ]]; then
  notify "OCR produced no output."
  exit 1
fi

TEXT="$(cat "${OUT}.txt")"
TEXT="${TEXT%"${TEXT##*[![:space:]]}"}"

if [[ -z "$TEXT" ]]; then
  notify "No text found in the selected area."
  exit 0
fi

if ! copy_to_clipboard "$TEXT"; then
  notify "No clipboard tool found (install xclip or wl-clipboard)."
  exit 1
fi

notify "Text extracted and copied to clipboard."
exit 0
