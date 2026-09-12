# Changelog

All notable changes to VoxSnip are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- Text extraction shortcut is now `Alt+W` so it is less likely to be captured by the focused app.
- Area capture uses GNOME Shell's selection overlay on Wayland, then falls back to `gnome-screenshot`.

## [0.1.0] — 2026-09-12

### Added

- Area screenshot to clipboard (`Alt+S`)
- Local Tesseract OCR to clipboard (`Alt+W`)
- Interactive Debian/Ubuntu installer with optional language packs
- Configurable OCR languages via `~/.config/voxsnip/langs.conf`
- GNOME custom shortcut binding
- Product site at [voxsnip.voxonlabs.com](https://voxsnip.voxonlabs.com)
- Uninstall script
