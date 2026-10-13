# VoxSnip Platform Expansion Phases

This document describes how VoxSnip should grow from an Ubuntu/GNOME utility
into a dependable Linux, macOS, and Windows product without losing its defining
behavior:

- one shortcut for an image: select, release, image is on the clipboard;
- one shortcut for text: select, release, only recognized text is on the clipboard;
- processing stays local;
- no account, upload, editor, or mandatory cloud service;
- no screenshot file is retained unless the user explicitly asks for one.

The order is deliberate: **Linux breadth first, then macOS, then Windows**.
Each phase has an exit gate. Work should not advance merely because a prototype
runs on one developer machine.

## Product contract

Every supported platform must implement the same logical pipeline:

```text
global shortcut
  -> select area or window
  -> capture pixels into an ephemeral buffer/file
  -> screenshot: copy image to clipboard
     OCR: recognize locally, destroy image, copy text to clipboard
  -> show a small success/error notification
```

The platform boundary should expose four operations:

```text
ShortcutBackend.register(actions)
CaptureBackend.selectAndCapture(target) -> Image
OcrBackend.recognize(image, languages) -> Text
ClipboardBackend.write(image | text)
```

This contract matters more than sharing implementation code. Do not force one
GUI framework or capture API across all operating systems if native APIs produce
a safer, faster result.

## Phase 0 — Harden the current GNOME product

**Goal:** make Ubuntu/GNOME a trustworthy reference implementation.

### Deliverables

- Finish the direct-selection companion and portal-v3 fallback.
- Version the installer and expose `voxsnip --version` or an equivalent command.
- Add an upgrade path that preserves OCR languages and shortcut choices.
- Add a diagnostic command that reports session type, desktop, portal version,
  selected backend, OCR languages, and clipboard backend without capturing data.
- Prevent concurrent captures and make `Esc` cancellation silent and final.
- Test mixed-DPI and multi-monitor layouts, including a monitor left of the
  primary display.
- Test GNOME Shell upgrades and companion compatibility separately from the
  command-line scripts.
- Create a release checklist covering source/public mirrors, website assets,
  installer smoke tests, uninstall, and rollback.

### Support target

- Current Ubuntu LTS and the newest Ubuntu release.
- GNOME Shell 45–50 while those versions remain practical to test.
- Wayland as the primary target; X11 as a compatibility target.

### Exit gate

- Fresh install, upgrade, and uninstall pass in clean virtual machines.
- `Alt+S` and `Alt+W` pass on single-monitor, multi-monitor, and scaled displays.
- OCR never leaves an image in the clipboard or a retained screenshot on disk.
- A GNOME Shell update cannot be released without the compatibility matrix being
  tested or explicitly narrowed.

## Phase 1 — Fedora Workstation

**Goal:** support Fedora GNOME without forking the product.

Fedora is the best first expansion because it keeps GNOME/Wayland constant while
changing installation, dependency names, release cadence, and security defaults.

### Engineering work

- Split installation into package-manager adapters instead of adding `dnf`
  conditionals throughout one script:
  - Debian/Ubuntu: `apt-get`;
  - Fedora: `dnf`;
  - later RPM systems: reuse the RPM adapter where package names match.
- Add a non-interactive core installer with a thin interactive front end.
- Map dependencies by capability rather than assuming Debian package names:
  Python GI, Tesseract, language packs, clipboard support, notifications, and
  GNOME Shell integration.
- Test under enforcing SELinux. Do not instruct users to disable SELinux.
- Create an RPM spec and initially publish test builds through a controlled COPR
  repository; pursue Fedora repository review only after the package stabilizes.
- Ensure Silverblue/Kinoite users have a supported path. Prefer a Flatpak or
  user-level install over asking users to layer many host packages.

Fedora offers both traditional RPM-based systems and image-based variants, so
packaging must account for both rather than treating `dnf install` as universal.
[Fedora package-management overview](https://docs.fedoraproject.org/en-US/fedora/f28/system-administrators-guide/package-management/intro-package-management/)

### Test matrix

| System | Session | Required result |
| --- | --- | --- |
| Fedora Workstation current | GNOME Wayland | Full support |
| Fedora Workstation previous | GNOME Wayland | Full support |
| Fedora Workstation | GNOME X11, if offered | Compatibility support |
| Fedora Silverblue current | GNOME Wayland | Documented supported install |

### Exit gate

- The same behavior suite passes on Ubuntu and Fedora.
- RPM install, upgrade, and removal do not modify unrelated GNOME shortcuts or
  extensions.
- SELinux remains enforcing.
- Fedora-specific code is confined to packaging and capability discovery.

## Phase 2 — Other Linux desktops and distributions

**Goal:** support Linux by desktop capability, then make distribution packages.

Linux capture behavior is controlled more by the desktop/compositor and its
portal backend than by whether the system is Arch, Debian, or Fedora. XDG Desktop
Portal currently lists distinct backends for GNOME, KDE, wlroots, LXQt,
Pantheon, Deepin, Xapp, and COSMIC.
[Portal backend overview](https://flatpak.github.io/xdg-desktop-portal/docs/)

### 2A — Build a capability-driven Linux backend

Choose at runtime in this order:

1. Screenshot portal v3 with the explicit Area target.
2. A desktop-native trusted companion where the portal cannot provide the
   select-and-release experience.
3. A compositor tool adapter, such as the wlroots ecosystem, when installed.
4. An X11 area-capture adapter.
5. The legacy interactive portal as a clearly identified fallback.

Do not infer capability solely from `$XDG_CURRENT_DESKTOP`. Query portal versions
and advertised targets. Portal backend selection itself is desktop-configurable.
[Portal configuration](https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html)

### 2B — Replace desktop-specific shortcut installation

- Prefer the XDG Global Shortcuts portal where implemented.
- Preserve desktop-native bindings as fallback adapters.
- Detect conflicts and let the user choose alternatives; never silently replace
  an existing shortcut.
- Store actions (`screenshot`, `ocr`) separately from their preferred keys.

The Global Shortcuts portal supports persistent shortcut sessions and activation
signals, but availability must be detected rather than assumed.
[Global Shortcuts portal](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.GlobalShortcuts.html)

### 2C — Desktop rollout order

1. KDE Plasma on Wayland.
2. wlroots compositors: Sway and Hyprland as initial representatives.
3. Cinnamon, MATE, and Xfce through Xapp/X11-compatible paths.
4. COSMIC after its portal behavior is stable enough to test.

For each desktop, publish a support level:

- **Full:** direct select-and-release, both shortcuts, local OCR, clipboard.
- **Compatible:** works, but uses a desktop chooser or requires shortcut setup.
- **Unsupported:** known not to work; fail with an actionable message.

### 2D — Distribution and packaging order

1. `.deb` repository for Ubuntu/Debian.
2. RPM/COPR for Fedora, then RPM artifacts for compatible systems.
3. Arch User Repository package after the install layout is stable.
4. Flatpak when screenshot and shortcut portals can deliver the promised UX.
5. AppImage only if update verification and desktop integration are solved.

Flatpak should not be treated as a shortcut around portal limitations. It is a
good distribution format only when the required capture and global-shortcut
interfaces work on the target desktop.

### Linux exit gate

- Automated tests cover backend selection and failure messages.
- Manual release testing covers GNOME, KDE, one wlroots compositor, and X11.
- Ubuntu, Fedora, and one rolling distribution have reproducible packages.
- The website publishes an honest desktop/distro compatibility table.
- No supported install path depends on `curl | bash` as its only update system.

## Phase 3 — Stabilize the cross-platform core contract

**Goal:** prepare for native macOS and Windows implementations without rewriting
product rules three times.

### Deliverables

- Define fixtures for OCR input/output, whitespace normalization, language
  selection, cancellation, and clipboard payloads.
- Define the settings schema: shortcuts, OCR languages, notifications, capture
  target, and privacy behavior.
- Define a backend conformance suite based on the product contract.
- Decide whether a small shared core is justified. Rust is a candidate for
  configuration, image normalization, and orchestration, but native adapters
  should own screen capture, permissions, hotkeys, clipboard, and notifications.
- Keep OCR pluggable:
  - Linux: Tesseract initially;
  - macOS: Vision;
  - Windows: Windows OCR;
  - optional Tesseract fallback only where native OCR lacks required languages.

### Exit gate

- A new platform adapter can implement the contract without importing Linux
  shell scripts or duplicating behavioral decisions.
- Golden OCR and clipboard tests run identically across supported platforms.

## Phase 4 — macOS

**Goal:** ship a native, signed menu-bar application with the same two actions.

### Recommended implementation

- Swift with AppKit or SwiftUI plus AppKit where lower-level control is needed.
- A menu-bar app with configurable shortcuts and no required Dock window.
- ScreenCaptureKit for capture, using the system content picker where required
  and a lightweight multi-display overlay for area selection where permitted.
- Vision `VNRecognizeTextRequest` for on-device OCR.
- `NSPasteboard.general` for PNG and recognized text.
- Native notifications and a first-run permissions screen.

Apple recommends ScreenCaptureKit for screen content and its system picker for
user-selected sources. Vision performs text recognition on-device, and
`NSPasteboard` is the native clipboard interface.
[ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit),
[Vision text recognition](https://developer.apple.com/documentation/vision/recognizing-text-in-images),
[NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard)

### Permission strategy

- Explain Screen Recording permission before triggering the system prompt.
- Request Accessibility permission only if the chosen global-shortcut mechanism
  truly requires it; avoid collecting a broader permission for convenience.
- Detect revoked permissions and link directly to the relevant System Settings
  page.
- Never fall back to uploading screenshots for OCR.

### Distribution order

1. Signed and notarized universal build for Apple silicon and Intel, if Intel is
   still within the chosen support window.
2. DMG download with Sparkle or another signed update mechanism.
3. Homebrew Cask.
4. Mac App Store only after sandbox, shortcut, and capture constraints are
   proven compatible with the product experience.

### Exit gate

- First-run permissions are understandable and recoverable.
- Both shortcuts work across multiple Spaces, displays, and Retina scale factors.
- Image and text clipboard formats paste correctly into common native and browser
  applications.
- The app is signed, notarized, updateable, and passes a clean-machine test.

## Phase 5 — Windows

**Goal:** ship a native Windows 11 tray application with behavioral parity.

### Recommended implementation

- C#/.NET with WinUI 3 or a small Win32 host, selecting the option that produces
  the most reliable overlay and tray lifecycle.
- `RegisterHotKey` for configurable system-wide shortcuts, with conflict
  detection and `MOD_NOREPEAT` behavior.
- A transparent per-monitor selection overlay with correct logical/physical DPI
  conversion.
- Prefer the packaged Snipping Tool integration when its response flow fits the
  UX; otherwise use Windows Graphics Capture for the selected display/window and
  crop the chosen rectangle.
- Windows OCR APIs for local recognition.
- Native clipboard formats for PNG/DIB and Unicode text.
- MSIX identity from the beginning, because both newer capture-response flows
  and Windows OCR features benefit from or require packaged identity.

Microsoft documents a packaged-app response flow for Snipping Tool, system-wide
hotkeys through `RegisterHotKey`, OCR through `Windows.Media.Ocr`, and clipboard
ownership through the Win32 clipboard APIs.
[Snipping Tool integration](https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-snipping-tool),
[RegisterHotKey](https://learn.microsoft.com/en-in/windows/win32/api/winuser/nf-winuser-registerhotkey),
[Windows OCR](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr),
[SetClipboardData](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setclipboarddata)

### Distribution order

1. Signed MSIX distributed from the VoxSnip website.
2. `winget` manifest and automated update validation.
3. Microsoft Store after the direct distribution build is stable.

### Exit gate

- Windows 11 current and previous supported feature releases pass the behavior
  suite.
- Mixed-DPI multi-monitor selection is pixel-accurate.
- Shortcut conflicts, clipboard contention, and permission denial produce
  recoverable messages.
- The package is signed, uninstallable, and updateable without losing settings.

## Phase 6 — One product, multiple native implementations

**Goal:** operate VoxSnip as a coherent product rather than three unrelated apps.

### Release engineering

- Use one semantic product version with platform-specific build numbers.
- Produce signed checksums and a software bill of materials for every release.
- Run platform builds in isolated CI runners:
  - Linux matrix for packages and desktop integration tests;
  - macOS runner for build, tests, signing, and notarization;
  - Windows runner for MSIX build, signing, and installation tests.
- Keep release channels explicit: stable, beta, and development.
- Publish platform support and known limitations beside every download.

### Product quality

- Measure only opt-in, privacy-preserving operational data if telemetry is ever
  introduced. The default remains no telemetry.
- Maintain local-only OCR as a hard product guarantee.
- Keep shortcut behavior, notifications, cancellation, whitespace cleanup, and
  clipboard results consistent across platforms.
- Document accessibility: keyboard-only selection, screen-reader labels,
  contrast, reduced motion, and configurable shortcuts.

## Priority rule

When deciding what to build next, use this order:

1. Reliability of the two core actions.
2. Safe permissions and local processing.
3. Desktop/platform coverage.
4. Reproducible installation and updates.
5. Convenience features.

Do not add screenshot history, cloud sync, editing, accounts, or AI services
until the supported-platform matrix is reliable. Breadth without predictable
capture and clipboard behavior would weaken the product rather than expand it.

## Immediate next milestones

- [ ] Complete Phase 0 release and test it on clean Ubuntu GNOME machines.
- [ ] Refactor the installer into dependency, install, shortcut, and package
      manager layers.
- [ ] Add Fedora dependency mapping and Fedora Workstation CI/smoke-test notes.
- [ ] Produce the first RPM/COPR beta.
- [ ] Write the Linux backend capability probe and compatibility report.
- [ ] Prototype KDE portal-v3 capture before starting macOS implementation.
- [ ] Freeze the cross-platform behavior contract before creating the macOS
      project.
