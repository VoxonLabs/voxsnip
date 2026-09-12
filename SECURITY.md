# Security Policy

VoxSnip is a local Linux desktop utility. Screenshots and OCR are intended to stay on the user's machine.

## Supported versions

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Older published copies | Best effort |

## In scope

- Installer and uninstall scripts
- Screenshot and OCR helper scripts
- Accidental network exfiltration of captured images or recognized text
- Privilege issues introduced by this repository (sudo usage in the installer, shortcut command injection)
- The public site files in `public/`

## Out of scope

- Bugs in Tesseract, GNOME Screenshot, `xclip`, `wl-clipboard`, or the desktop environment
- OCR accuracy
- Compromised user sessions or malicious local processes
- Third-party hosting, DNS, or CDN issues unrelated to this repository

## Reporting

Email [security@voxonlabs.com](mailto:security@voxonlabs.com).

Include the affected file or command, the desktop environment and Ubuntu version, and steps to reproduce. Do not file a public issue for vulnerabilities that could be used to read another user's screen, overwrite shortcuts, or execute unexpected commands.

We will acknowledge reports when we can and prefer coordinated disclosure.

## Installer caution

The documented install path is:

```bash
curl -fsSL https://voxsnip.voxonlabs.com/install.sh | bash
```

That command runs whatever the URL returns. Prefer cloning this repository and running `bash public/install.sh` if you want to inspect the script first.
