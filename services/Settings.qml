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
    // the weather (the Today card, the weather widget): a city, and celsius or fahrenheit. Kept here only, on this
    // machine; empty at first, it starts from liquid's weather widget if there is one
    property string city: ""
    property string units: "celsius"
    // night light (Night): off · on · auto (from nightFrom to nightTo o'clock); how warm, in kelvin
    property string nightMode: "off"
    property int nightTemp: 4000
    property int nightFrom: 20
    property int nightTo: 7
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
                for (const k of ["city", "units", "nightMode"])
                    if (typeof d[k] === "string")
                        root[k] = d[k];
                for (const k of ["nightTemp", "nightFrom", "nightTo"])
                    if (typeof d[k] === "number")
                        root[k] = d[k];
            } catch (e) {}
            root.loaded = true;
            if (!root.city)
                liquid.reload();
        }
        onLoadFailed: {
            root.loaded = true;
            liquid.reload();
        }
    }
    Timer {
        id: saveLater
        interval: 300
        onTriggered: {
            Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/pureshell"]);
            file.setText(JSON.stringify({ barStyle: root.barStyle, city: root.city, units: root.units, nightMode: root.nightMode, nightTemp: root.nightTemp, nightFrom: root.nightFrom, nightTo: root.nightTo }) + "\n");
        }
    }

    // a first city: the one liquid's weather widget uses, if it has one
    FileView {
        id: liquid
        path: Quickshell.env("HOME") + "/.local/state/ekitai/widgets.json"
        printErrors: false
        onLoaded: {
            if (!root.loaded)                    // (once ours is read: then only if it had no city)
                return;
            try {
                const w = JSON.parse(text()).widgets.find(w => w.type === "weather" && w.props?.city);
                if (w && !root.city) {
                    root.city = w.props.city;
                    root.units = w.props.units ?? root.units;
                }
            } catch (e) {}
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
