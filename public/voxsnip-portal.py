#!/usr/bin/env python3
# VoxSnip — ask GNOME for an interactive screenshot via xdg-desktop-portal
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only
"""Print a selected-area PNG path on stdout. Exit 1 if cancelled.

Prefer VoxSnip's GNOME Shell companion, which finishes as soon as the user
releases the mouse. Then try Screenshot portal v3's explicit Area target.
The legacy interactive chooser remains as a compatibility fallback.
"""

from __future__ import annotations

import sys
from urllib.parse import unquote, urlparse

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

DIRECT_BUS = "com.voxonlabs.VoxSnip"
DIRECT_PATH = "/com/voxonlabs/VoxSnip"
DIRECT_IFACE = "com.voxonlabs.VoxSnip"
AREA_TARGET = 4


def try_direct_capture(bus: Gio.DBusConnection) -> tuple[bool, str | None]:
    """Return (handled, path) for the Shell companion."""
    try:
        reply = bus.call_sync(
            DIRECT_BUS,
            DIRECT_PATH,
            DIRECT_IFACE,
            "CaptureArea",
            None,
            GLib.VariantType.new("(bs)"),
            Gio.DBusCallFlags.NO_AUTO_START,
            120_000,
            None,
        )
        success, path = reply.unpack()
        if success and path:
            return True, str(path)
        return True, None
    except GLib.Error:
        pass
    return False, None


def uint_property(proxy: Gio.DBusProxy, name: str) -> int:
    value = proxy.get_cached_property(name)
    return int(value.unpack()) if value is not None else 0


def main() -> int:
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    direct_handled, direct_path = try_direct_capture(bus)
    if direct_handled:
        if direct_path:
            print(direct_path)
            return 0
        return 1

    proxy = Gio.DBusProxy.new_sync(
        bus,
        Gio.DBusProxyFlags.NONE,
        None,
        "org.freedesktop.portal.Desktop",
        "/org/freedesktop/portal/desktop",
        "org.freedesktop.portal.Screenshot",
        None,
    )

    loop = GLib.MainLoop()
    result: dict[str, object] = {}

    def on_signal(_conn, _sender, _path, _iface, _signal, params) -> None:
        result["response"] = params.unpack()
        loop.quit()

    bus.signal_subscribe(
        "org.freedesktop.portal.Desktop",
        "org.freedesktop.portal.Request",
        "Response",
        None,
        None,
        Gio.DBusSignalFlags.NONE,
        on_signal,
    )

    def on_call(source, res, _data) -> None:
        try:
            source.call_finish(res).unpack()[0]
        except Exception as exc:  # noqa: BLE001
            result["error"] = str(exc)
            loop.quit()

    options: dict[str, GLib.Variant] = {
        "interactive": GLib.Variant("b", True),
    }
    # Portal v3 can enter the area picker directly. Older portals ignore or
    # reject this option, so only send it when both version and target agree.
    if uint_property(proxy, "version") >= 3:
        available = uint_property(proxy, "AvailableTargets")
        if available & AREA_TARGET:
            options["interactive"] = GLib.Variant("b", False)
            options["target"] = GLib.Variant("u", AREA_TARGET)

    proxy.call(
        "Screenshot",
        GLib.Variant("(sa{sv})", ("", options)),
        Gio.DBusCallFlags.NONE,
        120000,
        None,
        on_call,
        None,
    )
    GLib.timeout_add_seconds(120, lambda: (result.setdefault("error", "timeout"), loop.quit(), False)[2])
    loop.run()

    if "error" in result:
        print(result["error"], file=sys.stderr)
        return 1

    response = result.get("response")
    if not response:
        return 1
    code, payload = response
    if int(code) != 0:
        return 1
    uri = str(payload.get("uri", ""))
    if not uri:
        return 1
    path = unquote(urlparse(uri).path)
    print(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
