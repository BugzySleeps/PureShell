pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth: on or off, and what's connected.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string name: !enabled ? "Off" : connected.length ? connected[0].name : "On"

    function toggle() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
}
