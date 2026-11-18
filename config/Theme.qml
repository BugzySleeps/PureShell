pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// PureShell's look: creamy white (#edeae4) and one warm charcoal ink, Google Sans Flex, Material Symbols, soft
// round shapes and springy motion. The colours come from ~/.local/state/rice/palette.json (the `pure` theme),
// with the same cream built in until it's read.
Singleton {
    id: root

    // ── colours ──
    readonly property color cream: pick("bg1", "#edeae4")      // the island, the bar, panels
    readonly property color creamHi: pick("bg0", "#f5f3ef")    // cards on them, popups
    readonly property color well: pick("bg2", "#e3dfd7")       // tracks, pressed, empty dots
    readonly property color line: pick("bg3", "#d6d0c5")       // dividers, outlines
    readonly property color ink: pick("fg", "#2a2520")         // text and icons
    readonly property color inkSoft: pick("accent2", "#5c544b")
    readonly property color muted: pick("dim", "#8d8478")      // secondary text
    readonly property color shadow: Qt.rgba(0.16, 0.14, 0.12, 0.16)
    // the island and the bar: the cream, a breath see-through (Hyprland frosts behind it)
    readonly property color surface: Qt.alpha(cream, 0.94)

    // (only the `pure` theme's palette: run beside another rice's shell, it keeps its own cream)
    readonly property bool ours: data.name === "pure"
    readonly property string wallpaper: ours && data.wallpaper ? data.wallpaper : Quickshell.env("HOME") + "/.config/rice/themes/pure/wallpaper.png"

    // ── type and icons ──
    readonly property string font: "Google Sans Flex"
    readonly property string icons: "Material Symbols Rounded"
    readonly property int text: 13
    readonly property int small: 11
    readonly property int big: 16

    // ── shape and motion ──
    readonly property int gap: 8                 // from the screen's edge
    readonly property int islandHeight: 36
    readonly property int barHeight: 40
    readonly property int fast: 140
    readonly property int med: 260
    readonly property int slow: 460

    property var data: ({})
    function pick(key, fallback) {
        return ours ? (data.colors?.[key] ?? fallback) : fallback;
    }
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/rice/palette.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {}                           // half-written: the next change has the rest
        }
    }
}
