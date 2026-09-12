#!/usr/bin/env python3
# VoxSnip — ask GNOME for an interactive screenshot via xdg-desktop-portal
# Copyright (c) 2026 Voxon Labs
# SPDX-License-Identifier: AGPL-3.0-only
"""Print the captured PNG path on stdout. Exit 1 if the user cancels."""

from __future__ import annotations

import sys
from urllib.parse import unquote, urlparse

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib


def main() -> int:
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
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

    proxy.call(
        "Screenshot",
        GLib.Variant("(sa{sv})", ("", {"interactive": GLib.Variant("b", True)})),
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
