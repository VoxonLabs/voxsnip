#!/usr/bin/env bash
# VoxSnip installer — Voxon Labs
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only
# Usage:
#   curl -fsSL https://voxsnip.voxonlabs.com/install.sh | bash
#   bash public/install.sh
set -u

readonly APP_NAME="VoxSnip"
readonly VENDOR="VoxonLabs"
readonly BIN_DIR="${HOME}/.local/bin"
readonly CONFIG_DIR="${HOME}/.config/voxsnip"
readonly LANGS_CONF="${CONFIG_DIR}/langs.conf"
readonly CLIP_NAME="voxsnip-clip.sh"
readonly TEXT_NAME="voxsnip-text.sh"
readonly UNINSTALL_NAME="voxsnip-uninstall.sh"

readonly GH_RAW="https://raw.githubusercontent.com/VoxonLabs/voxsnip/main/src"
readonly WEB_BASE="https://voxsnip.voxonlabs.com"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

INPUT="/dev/tty"
if [[ ! -r "$INPUT" ]]; then
  INPUT="/dev/stdin"
fi

if [[ -t 1 ]]; then
  BOLD='\033[1m'
  DIM='\033[2m'
  CYAN='\033[36m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  RED='\033[31m'
  RESET='\033[0m'
else
  BOLD='' DIM='' CYAN='' GREEN='' YELLOW='' RED='' RESET=''
fi

info()  { printf "${CYAN}==>${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}==>${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}==>${RESET} %s\n" "$*"; }
fail()  { printf "${RED}==>${RESET} %s\n" "$*" >&2; }

die() {
  fail "$*"
  exit 1
}

ask_yes_no() {
  local prompt="$1"
  local default="$2"
  local reply=""
  local hint

  if [[ "$default" == "y" ]]; then
    hint="Y/n"
  else
    hint="y/N"
  fi

  printf "${BOLD}%s${RESET} [%s] " "$prompt" "$hint" > /dev/tty 2>/dev/null || printf "%s [%s] " "$prompt" "$hint"
  if ! IFS= read -r reply < "$INPUT"; then
    reply=""
  fi
  reply="$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"

  if [[ -z "$reply" ]]; then
    [[ "$default" == "y" ]]
    return $?
  fi
  [[ "$reply" == "y" || "$reply" == "yes" ]]
}

welcome() {
  printf "\n"
  printf "${CYAN}${BOLD}"
  cat <<'BANNER'
 __     __          ____        _
 \ \   / /____  __ / ___| _ __ (_)_ __
  \ \ / / _ \ \/ / \___ \| '_ \| | '_ \
   \ V / (_) >  <   ___) | | | | | |_) |
    \_/ \___/_/\_\ |____/|_| |_|_| .__/
                                 |_|
BANNER
  printf "${RESET}"
  printf "  ${BOLD}%s by %s${RESET}\n" "$APP_NAME" "$VENDOR"
  printf "  ${DIM}Linux snipping + OCR  ·  Alt+S screenshot  ·  Alt+T extract text${RESET}\n\n"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_packages() {
  local packages=("$@")
  if ! require_cmd apt-get; then
    die "This installer requires apt-get (Debian/Ubuntu)."
  fi
  if ! require_cmd sudo; then
    die "sudo is required to install packages."
  fi

  info "Updating package lists..."
  sudo apt-get update -y || die "apt-get update failed."

  info "Installing: ${packages[*]}"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" \
    || die "Package installation failed."
  ok "Dependencies installed."
}

resolve_script() {
  local name="$1"
  local dest="$2"
  local candidates=(
    "${SCRIPT_DIR}/../src/${name}"
    "${SCRIPT_DIR}/${name}"
    "${PWD}/src/${name}"
    "${PWD}/../src/${name}"
  )
  local src

  for src in "${candidates[@]}"; do
    if [[ -f "$src" ]]; then
      cp "$src" "$dest"
      return 0
    fi
  done

  local urls=(
    "${WEB_BASE}/${name}"
    "${GH_RAW}/${name}"
  )
  local url
  for url in "${urls[@]}"; do
    if require_cmd curl && curl -fsSL "$url" -o "$dest"; then
      return 0
    fi
    if require_cmd wget && wget -qO "$dest" "$url"; then
      return 0
    fi
  done

  return 1
}

install_scripts() {
  mkdir -p "$BIN_DIR"
  local clip="${BIN_DIR}/${CLIP_NAME}"
  local text="${BIN_DIR}/${TEXT_NAME}"
  local uninstall="${BIN_DIR}/${UNINSTALL_NAME}"

  info "Installing scripts to ${BIN_DIR}..."
  resolve_script "$CLIP_NAME" "$clip" || die "Could not obtain ${CLIP_NAME}."
  resolve_script "$TEXT_NAME" "$text" || die "Could not obtain ${TEXT_NAME}."
  resolve_script "$UNINSTALL_NAME" "$uninstall" || die "Could not obtain ${UNINSTALL_NAME}."
  chmod +x "$clip" "$text" "$uninstall"
  ok "Scripts installed and marked executable."
}

write_langs_conf() {
  local langs="$1"
  mkdir -p "$CONFIG_DIR"
  cat > "$LANGS_CONF" <<EOF
# VoxSnip Tesseract language string (VoxonLabs)
# Edit this file to change OCR languages, e.g. eng+jpn+nep
${langs}
EOF
  ok "Saved OCR languages (${langs}) to ${LANGS_CONF}"
}

gsettings_paths() {
  local raw
  raw="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true)"
  printf '%s' "$raw" | grep -oE '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom[0-9]+/' || true
}

next_custom_path() {
  local used="$1"
  local i=0
  local candidate
  while true; do
    candidate="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${i}/"
    if ! printf '%s\n' "$used" | grep -Fxq "$candidate"; then
      printf '%s' "$candidate"
      return 0
    fi
    i=$((i + 1))
  done
}

find_binding_path_by_name() {
  local want_name="$1"
  local path name
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    name="$(gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${path}" name 2>/dev/null || true)"
    name="${name#\'}"
    name="${name%\'}"
    if [[ "$name" == "$want_name" ]]; then
      printf '%s' "$path"
      return 0
    fi
  done <<< "$(gsettings_paths)"
  return 1
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

bind_shortcut() {
  local name="$1"
  local command="$2"
  local accel="$3"
  local schema_item="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
  local path
  local -a all_paths=()
  local existing

  existing="$(gsettings_paths)"
  while IFS= read -r path; do
    [[ -n "$path" ]] && all_paths+=("$path")
  done <<< "$existing"

  path="$(find_binding_path_by_name "$name" || true)"
  if [[ -z "$path" ]]; then
    path="$(next_custom_path "$existing")"
    all_paths+=("$path")
    write_keybinding_list "${all_paths[@]}"
  fi

  gsettings set "${schema_item}:${path}" name "$name"
  gsettings set "${schema_item}:${path}" command "$command"
  gsettings set "${schema_item}:${path}" binding "$accel"
}

setup_shortcuts() {
  if ! require_cmd gsettings; then
    warn "gsettings not found. Skipping automatic keyboard shortcuts."
    warn "Bind Alt+S → ${BIN_DIR}/${CLIP_NAME}"
    warn "Bind Alt+T → ${BIN_DIR}/${TEXT_NAME}"
    return 0
  fi

  if ! gsettings list-keys org.gnome.settings-daemon.plugins.media-keys >/dev/null 2>&1; then
    warn "GNOME media-keys schema unavailable. Skipping automatic shortcuts."
    return 0
  fi

  info "Binding GNOME shortcuts (Alt+S, Alt+T)..."
  bind_shortcut "VoxSnip Screenshot" "${BIN_DIR}/${CLIP_NAME}" "<Alt>s"
  bind_shortcut "VoxSnip Text Extractor" "${BIN_DIR}/${TEXT_NAME}" "<Alt>t"
  ok "Shortcuts bound: Alt+S (snip) and Alt+T (OCR)."
}

ensure_local_bin_path() {
  case ":${PATH}:" in
    *":${BIN_DIR}:"*) return 0 ;;
  esac

  local profile="${HOME}/.profile"
  if [[ -f "$profile" ]] && grep -q '\.local/bin' "$profile" 2>/dev/null; then
    warn "${BIN_DIR} is not on PATH in this session. Shortcuts use full paths, so they still work."
    return 0
  fi

  if [[ -f "${HOME}/.bashrc" ]] && ! grep -Fq '.local/bin' "${HOME}/.bashrc"; then
    {
      printf '\n# VoxSnip (VoxonLabs)\n'
      printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    } >> "${HOME}/.bashrc"
    warn "Added ${BIN_DIR} to PATH in ~/.bashrc (new terminals only)."
  fi
}

main() {
  welcome

  info "Select Tesseract OCR language packs to install."
  printf "${DIM}English is recommended and selected by default.${RESET}\n\n"

  local packages=(
    gnome-screenshot
    tesseract-ocr
    xclip
    wl-clipboard
    libnotify-bin
  )
  local tess_langs=()

  if ask_yes_no "English / US / UK  (tesseract-ocr-eng)" "y"; then
    packages+=(tesseract-ocr-eng)
    tess_langs+=(eng)
  fi

  if ask_yes_no "European languages  Spanish / French / German" "n"; then
    packages+=(tesseract-ocr-spa tesseract-ocr-fra tesseract-ocr-deu)
    tess_langs+=(spa fra deu)
  fi

  if ask_yes_no "Japanese & vertical text  (tesseract-ocr-jpn, tesseract-ocr-jpn-vert)" "n"; then
    packages+=(tesseract-ocr-jpn tesseract-ocr-jpn-vert)
    tess_langs+=(jpn jpn_vert)
  fi

  if ask_yes_no "Nepali  (tesseract-ocr-nep)" "n"; then
    packages+=(tesseract-ocr-nep)
    tess_langs+=(nep)
  fi

  if [[ ${#tess_langs[@]} -eq 0 ]]; then
    warn "No languages selected. Defaulting to English (eng)."
    packages+=(tesseract-ocr-eng)
    tess_langs+=(eng)
  fi

  local lang_string
  lang_string="$(IFS=+; printf '%s' "${tess_langs[*]}")"

  printf "\n"
  info "OCR language string: ${BOLD}-l ${lang_string}${RESET}"
  printf "\n"

  install_packages "${packages[@]}"
  install_scripts
  write_langs_conf "$lang_string"
  setup_shortcuts
  ensure_local_bin_path

  printf "\n"
  ok "${APP_NAME} is ready."
  printf "\n"
  printf "  ${BOLD}Alt+S${RESET}  Copy an area screenshot to the clipboard\n"
  printf "  ${BOLD}Alt+T${RESET}  Extract text from an area (OCR) and copy it\n"
  printf "\n"
  printf "  ${DIM}Languages: %s${RESET}\n" "$lang_string"
  printf "  ${DIM}Config:    %s${RESET}\n" "$LANGS_CONF"
  printf "  ${DIM}Scripts:   %s${RESET}\n" "$BIN_DIR"
  printf "  ${DIM}Uninstall: %s${RESET}\n\n" "${BIN_DIR}/${UNINSTALL_NAME}"
}

main "$@"
