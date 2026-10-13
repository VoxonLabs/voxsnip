# Changelog

All notable changes to VoxSnip are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Fedora Linux support with automatic distribution detection and `dnf` package management.
- Support for `~/.bash_profile` PATH configuration on Fedora and non-Debian distributions.
- Direct GNOME area selection: drag and release to finish, with no mode or capture-button click.
- Screenshot portal v3 Area-target support, with the legacy chooser retained as a fallback.

### Changed

- `Alt+W` uses only a temporary image for OCR and leaves recognized text—not an image—in the clipboard.

## [0.1.0] — 2026-09-12

First public release.

### Added

- Area screenshot to clipboard (`Alt+S`)
- Local Tesseract OCR to clipboard (`Alt+W`)
- Interactive Debian/Ubuntu installer with optional English, EU, Japanese, and Nepali packs
- Configurable OCR languages via `~/.config/voxsnip/langs.conf`
- GNOME custom shortcut binding
- Product site at [voxsnip.voxonlabs.com](https://voxsnip.voxonlabs.com)
- Uninstall script

### Fixed

- Area capture on GNOME 50 / Wayland now uses the xdg-desktop-portal screenshot UI. The Shell screenshot D-Bus API is denied, and `gnome-screenshot -a` writes an empty file.
- `Alt+W` keeps recognized text only. The portal PNG is removed and the image clipboard is overwritten so OCR does not also leave a screenshot.
