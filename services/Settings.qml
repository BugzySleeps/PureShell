pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// PureShell's choices, kept in ~/.local/state/pureshell/settings.json.
//   qs -c pureshell ipc call settings set barStyle '"bar"'
Singleton {
    id: root

    // "island": one cream island in the middle of the top edge, the clock, growing into what's happening;
    // "bar": a slim cream bar along the top, the island in its middle
    property string barStyle: "island"
    property bool loaded: false

    function set(key, value) {
        root[key] = value;
        saveLater.restart();
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/pureshell/settings.json"
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (["island", "bar"].includes(d.barStyle))
                    root.barStyle = d.barStyle;
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
    Timer {
        id: saveLater
        interval: 300
        onTriggered: {
            Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/pureshell"]);
            file.setText(JSON.stringify({ barStyle: root.barStyle }) + "\n");
        }
    }

    IpcHandler {
        target: "settings"
        function set(key: string, json: string): void {
            if (key in root)
                root.set(key, JSON.parse(json));
        }
        function barStyle(style: string): void {
            if (["island", "bar"].includes(style))
                root.set("barStyle", style);
        }
    }
}
