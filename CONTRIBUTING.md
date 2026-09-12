# Contributing to VoxSnip

Thank you for helping improve a Voxon Labs public project. By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## What belongs here

VoxSnip is a small, inspectable Linux utility. Useful contributions include:

- Installer robustness on current Ubuntu / GNOME releases
- Safer shortcut handling that does not clobber unrelated bindings
- Clipboard and Wayland/X11 edge cases
- Additional Tesseract language options that stay optional
- Documentation that stays factual

Please do not add telemetry, accounts, remote OCR, or a heavy application framework unless the maintainers ask for that work.

## Development setup

```bash
git clone https://github.com/VoxonLabs/voxsnip.git
cd voxsnip
bash -n src/voxsnip-clip.sh src/voxsnip-text.sh src/voxsnip-uninstall.sh public/install.sh
```

If `shellcheck` is installed:

```bash
shellcheck -x src/*.sh public/install.sh
```

Test on a GNOME session. The installer uses `sudo apt-get` and `gsettings`.

When you change a script in `src/`, copy it to `public/` as well so the product site and the repository stay aligned:

```bash
cp src/voxsnip-clip.sh src/voxsnip-text.sh src/voxsnip-uninstall.sh public/
```

## Pull requests

1. Open an issue first for behavior changes, unless the fix is obvious and small.
2. Keep commits focused.
3. Describe the desktop environment you tested (Ubuntu version, X11 or Wayland).
4. Do not commit secrets, local config from `~/.config/voxsnip`, or generated screenshots of private screens.

## Reporting bugs

Use a [bug report](https://github.com/VoxonLabs/voxsnip/issues/new?template=bug_report.yml) for functional problems. Use [SECURITY.md](SECURITY.md) for vulnerabilities.

## License

Contributions are accepted under AGPL-3.0-only, the license of this repository.
