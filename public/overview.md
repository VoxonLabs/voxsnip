# VoxSnip

Linux area screenshot and on-screen OCR, published by [Voxon Labs](https://voxonlabs.com).

**Website:** [voxsnip.voxonlabs.com](https://voxsnip.voxonlabs.com)

VoxSnip is a small GNOME desktop utility. Press `Alt+S` to copy a selected region to the clipboard, or `Alt+W` to extract text from that region with Tesseract and copy the result.

OCR runs locally. Selected pixels never leave the machine.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-111317.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%2F%20GNOME-111317.svg)](#requirements)
[![Website](https://img.shields.io/badge/website-voxsnip.voxonlabs.com-111317.svg)](https://voxsnip.voxonlabs.com)

## Install

On Debian or Ubuntu with GNOME:

```bash
curl -fsSL https://voxsnip.voxonlabs.com/install.sh | bash
```

The installer asks which Tesseract language packs to add, copies the scripts to `~/.local/bin`, writes `~/.config/voxsnip/langs.conf`, and binds the GNOME shortcuts.

Review the script before piping it to a shell:

```bash
curl -fsSL https://voxsnip.voxonlabs.com/install.sh
```

Or clone this repository and run it locally:

```bash
git clone https://github.com/VoxonLabs/voxsnip.git
cd voxsnip
bash public/install.sh
```

## Usage

| Shortcut | Action |
| --- | --- |
| `Alt+S` | Select a screen region and copy the image to the clipboard |
| `Alt+W` | Select a screen region, run Tesseract, and copy recognized text |

Desktop notifications confirm success, cancellation, or missing dependencies.

## OCR languages

The installer can add:

- English / US / UK (`eng`) — default
- European languages: Spanish, French, German (`spa`, `fra`, `deu`)
- Japanese, including vertical text (`jpn`, `jpn_vert`)
- Nepali (`nep`)

The active Tesseract `-l` string is stored in `~/.config/voxsnip/langs.conf`. Edit that file to change languages later, for example:

```text
eng+jpn+nep
```

Installed language packs must match the codes in that file.

## Requirements

Tested target: Ubuntu with GNOME.

| Package | Role |
| --- | --- |
| `gnome-screenshot` | Area capture |
| `tesseract-ocr` | Local OCR |
| `xclip` | X11 clipboard |
| `wl-clipboard` | Wayland clipboard |
| `libnotify-bin` | Desktop notifications |
| `tesseract-ocr-*` | Optional language data |

The installer installs these with `apt-get`. Shortcuts are set through `gsettings` and require a GNOME session.

## Configuration

```text
~/.local/bin/voxsnip-clip.sh
~/.local/bin/voxsnip-text.sh
~/.config/voxsnip/langs.conf
```

Shortcuts use absolute paths, so they work even when `~/.local/bin` is not on `PATH`.

To rebind keys, open **Settings → Keyboard → Keyboard Shortcuts → Custom Shortcuts**, or rerun the installer. Existing VoxSnip bindings are updated in place.

## Uninstall

```bash
bash src/voxsnip-uninstall.sh
```

Or from the published site after install:

```bash
curl -fsSL https://voxsnip.voxonlabs.com/voxsnip-uninstall.sh | bash
```

The uninstall script removes the user scripts, config directory, and GNOME custom shortcuts. It does not remove apt packages.

## Repository layout

```text
src/                 Runtime scripts (source of truth)
src/voxsnip-lib.sh   Shared area-capture helper
public/              Product site, installer, and mirrored scripts
LICENSE              GNU Affero General Public License v3.0
SECURITY.md          Vulnerability reporting
CONTRIBUTING.md      How to propose changes
CODE_OF_CONDUCT.md   Contributor Covenant
TRADEMARKS.md        Brand reservation
```

## Security

- Screenshots and OCR stay on the local machine.
- `curl | bash` executes remote code. Read the installer first, or run it from a clone.
- Report vulnerabilities privately. See [SECURITY.md](SECURITY.md).

## Contributing

Issues and pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) before opening work.

## License

Software in this repository is licensed under [AGPL-3.0-only](LICENSE).

Voxon Labs, VoxSnip, logos, and domain names are not licensed for reuse. See [TRADEMARKS.md](TRADEMARKS.md).

## Voxon Labs

VoxSnip is public work from Voxon Labs, based in Mayagüez, Puerto Rico.

- Company: [voxonlabs.com](https://voxonlabs.com)
- Public work: [voxonlabs.com/commons](https://voxonlabs.com/commons)
- Contact: [contact@voxonlabs.com](mailto:contact@voxonlabs.com)
