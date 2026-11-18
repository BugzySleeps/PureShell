pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The desktop widgets: where they are and how big, in grid cells (one cell is `cell` px), so they always sit on
// the grid; their shape and settings. Kept in ~/.local/state/pureshell/widgets.json.
// SUPER + W opens the workbench (desktop/Desktop.qml): the grid shows, the widgets lift above the windows to be
// moved and resized, and the drawer holds every kind to add.
//   qs -c pureshell ipc call widgets edit | open | close | add <kind> | remove <uid> | list | set <uid> <key> <json>
Singleton {
    id: root

    readonly property int cell: 32

    // every kind: its name, icon, size to start at and smallest (cells), the shape it starts in, the content's
    // smallest size (px: the shape grows to fit it), its settings
    readonly property var types: ({
            clock: { title: "Clock", icon: "schedule", w: 6, h: 3, minW: 4, minH: 2, shape: "box", need: [110, 50], props: {} },
            date: { title: "Date", icon: "today", w: 4, h: 4, minW: 3, minH: 3, shape: "cookie9", need: [62, 62], props: {} },
            calendar: { title: "Calendar", icon: "calendar_month", w: 7, h: 7, minW: 6, minH: 6, shape: "box", need: [180, 180], props: {} },
            weather: { title: "Weather", icon: "partly_cloudy_day", w: 7, h: 4, minW: 4, minH: 3, shape: "box", need: [110, 64], props: {} },
            music: { title: "Music", icon: "music_note", w: 9, h: 4, minW: 7, minH: 3, shape: "box", need: [200, 72], props: {} },
            note: { title: "Note", icon: "sticky_note_2", w: 6, h: 5, minW: 3, minH: 3, shape: "box", need: [80, 48], props: { text: "" } },
            analog: { title: "Analog", icon: "nest_clock_farsight_analog", w: 5, h: 5, minW: 4, minH: 4, shape: "circle", need: [96, 96], props: {} },
            system: { title: "System", icon: "monitor_heart", w: 9, h: 4, minW: 7, minH: 3, shape: "box", need: [210, 80], props: {} },
            battery: { title: "Battery", icon: "battery_full", w: 4, h: 4, minW: 3, minH: 3, shape: "cookie12", need: [66, 66], props: {} },
            storage: { title: "Storage", icon: "hard_drive", w: 4, h: 4, minW: 3, minH: 3, shape: "cookie6", need: [66, 66], props: {} },
            bars: { title: "Visualizer", icon: "graphic_eq", w: 8, h: 3, minW: 4, minH: 2, shape: "box", need: [110, 36], props: {} },
            todo: { title: "To-do", icon: "checklist", w: 6, h: 7, minW: 5, minH: 4, shape: "box", need: [140, 110], props: { items: [] } },
            timer: { title: "Focus", icon: "timer", w: 5, h: 5, minW: 4, minH: 4, shape: "squircle", need: [100, 100], props: { minutes: 25 } },
            photo: { title: "Photo", icon: "image", w: 6, h: 6, minW: 3, minH: 3, shape: "box", need: [60, 60], props: { path: "" } },
            greeting: { title: "Greeting", icon: "waving_hand", w: 10, h: 3, minW: 7, minH: 2, shape: "box", need: [230, 56], props: {} },
            sky: { title: "Sky", icon: "wb_twilight", w: 7, h: 4, minW: 4, minH: 3, shape: "box", need: [120, 70], props: {} }
        })
    readonly property var order: ["clock", "analog", "date", "calendar", "weather", "sky", "greeting", "music", "bars", "system", "battery", "storage", "todo", "timer", "note", "photo"]

    // [{ uid, type, x, y, w, h (cells), shape, angle (degrees: the shape turned, not what's in it), frame (a card
    //    behind it, or bare), props }]
    property var items: []
    property bool loaded: false
    property bool editing: false
    property string selected: ""                 // uid, while editing

    // the screen in cells (Desktop sets them), so new widgets land on it
    property int cols: 50
    property int rows: 28
    // a free spot for a w × h widget, as near (x, y) as there is one (rings outward); there if nothing's free
    function free(w, h, x, y, skip) {
        const fits = (a, b) => a >= 0 && b >= 2 && a + w <= cols && b + h <= rows
            && !items.some(i => i.uid !== skip && a < i.x + i.w && i.x < a + w && b < i.y + i.h && i.y < b + h);
        for (let r = 0; r < Math.max(cols, rows); r++)
            for (let dy = -r; dy <= r; dy++)
                for (let dx = -r; dx <= r; dx++)
                    if ((Math.abs(dx) === r || Math.abs(dy) === r) && fits(x + dx, y + dy))
                        return [x + dx, y + dy];
        return [x, y];
    }
    function add(type, x, y) {
        const t = types[type];
        if (!t)
            return;
        const at = free(t.w, t.h, Math.max(0, Math.min(cols - t.w, x ?? 3)), Math.max(2, Math.min(rows - t.h, y ?? 4)));
        const w = { uid: Date.now().toString(36) + Math.random().toString(36).slice(2, 6), type, x: at[0], y: at[1], w: t.w, h: t.h, shape: t.shape, frame: true, props: Object.assign({}, t.props) };
        items = items.concat([w]);
        selected = w.uid;
        save();
        return w.uid;
    }
    function remove(uid) {
        items = items.filter(w => w.uid !== uid);
        if (selected === uid)
            selected = "";
        save();
    }
    function find(uid) {
        return items.find(w => w.uid === uid) ?? null;
    }
    // change some of a widget (a new object, so everything bound to it follows)
    function update(uid, changes) {
        items = items.map(w => w.uid === uid ? Object.assign({}, w, changes) : w);
        save();
    }
    function setProp(uid, key, value) {
        const w = find(uid);
        if (!w)
            return;
        const p = Object.assign({}, w.props);
        p[key] = value;
        update(uid, { props: p });
    }

    function toggleEdit() {
        editing = !editing;
        if (!editing)
            selected = "";
    }

    function save() {
        if (loaded)
            saveLater.restart();
    }
    Timer {
        id: saveLater
        interval: 400
        onTriggered: {
            Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/pureshell"]);
            file.setText(JSON.stringify({ version: 1, widgets: root.items }, null, 1) + "\n");
        }
    }
    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/pureshell/widgets.json"
        printErrors: false
        onLoaded: {
            try {
                root.items = (JSON.parse(text()).widgets ?? []).filter(w => root.types[w.type]);
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: {                          // the first time: a date in a flower, the clock, the weather
            root.loaded = true;
            root.add("date", 3, 4);
            root.add("clock", 3, 9);
            root.add("weather", 3, 13);
            root.selected = "";
        }
    }

    IpcHandler {
        target: "widgets"
        function edit(): void {
            root.toggleEdit();
        }
        function open(): void {                  // the workbench, on / off (edit toggles it)
            if (!root.editing)
                root.toggleEdit();
        }
        function close(): void {
            if (root.editing)
                root.toggleEdit();
        }
        function add(type: string): void {
            root.add(type);
        }
        function remove(uid: string): void {
            root.remove(uid);
        }
        function set(uid: string, key: string, json: string): void {   // widgets set <uid> angle 30
            const c = {};
            c[key] = JSON.parse(json);
            root.update(uid, c);
        }
        function list(): string {
            return root.items.map(w => w.uid + "  " + w.type).join("\n");
        }
    }
}
