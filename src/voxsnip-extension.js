// VoxSnip — GNOME Shell direct area picker
// Copyright (c) 2026 Voxon Labs
// SPDX-License-Identifier: AGPL-3.0-only

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Shell from 'gi://Shell';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {SelectArea} from 'resource:///org/gnome/shell/ui/screenshot.js';

Gio._promisify(Shell.Screenshot.prototype, 'screenshot_area');

const BUS_NAME = 'com.voxonlabs.VoxSnip';
const OBJECT_PATH = '/com/voxonlabs/VoxSnip';
const INTERFACE_XML = `
<node>
  <interface name="com.voxonlabs.VoxSnip">
    <method name="CaptureArea">
      <arg name="success" type="b" direction="out"/>
      <arg name="path" type="s" direction="out"/>
    </method>
  </interface>
</node>`;

class CaptureService {
    constructor() {
        this._busy = false;
        this._dbus = Gio.DBusExportedObject.wrapJSObject(INTERFACE_XML, this);
        this._dbus.export(Gio.DBus.session, OBJECT_PATH);
        this._ownerId = Gio.bus_own_name_on_connection(
            Gio.DBus.session,
            BUS_NAME,
            Gio.BusNameOwnerFlags.NONE,
            null,
            null
        );
    }

    async CaptureAreaAsync(_params, invocation) {
        if (this._busy) {
            invocation.return_value(new GLib.Variant('(bs)', [false, '']));
            return;
        }

        this._busy = true;
        let path = '';
        let stream = null;
        try {
            const selector = new SelectArea();
            const area = await selector.selectAsync();
            if (!area)
                throw new Error('Area selection was cancelled');

            path = GLib.build_filenamev([
                GLib.get_user_runtime_dir(),
                `voxsnip-${GLib.uuid_string_random()}.png`,
            ]);
            const file = Gio.File.new_for_path(path);
            stream = file.replace(
                null, false, Gio.FileCreateFlags.PRIVATE, null);
            const shooter = new Shell.Screenshot();
            await shooter.screenshot_area(
                area.x, area.y, area.width, area.height, stream);
            stream.close(null);

            invocation.return_value(new GLib.Variant('(bs)', [true, path]));
        } catch {
            try {
                stream?.close(null);
            } catch (_closeError) {
                // The stream may already have been closed by the capture API.
            }
            if (path) {
                try {
                    Gio.File.new_for_path(path).delete(null);
                } catch (_deleteError) {
                    // The failed capture may not have created a file.
                }
            }
            invocation.return_value(new GLib.Variant('(bs)', [false, '']));
        } finally {
            this._busy = false;
        }
    }

    destroy() {
        this._dbus.unexport();
        Gio.bus_unown_name(this._ownerId);
    }
}

export default class VoxSnipExtension extends Extension {
    enable() {
        this._captureService = new CaptureService();
    }

    disable() {
        this._captureService?.destroy();
        this._captureService = null;
    }
}
