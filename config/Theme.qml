pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// PureShell's look: creamy white (#edeae4) and one warm charcoal ink, Google Sans Flex, Material Symbols, soft
// round shapes and springy motion; or dark mode, the same in warm charcoal with the cream for text. The colours
// come from ~/.local/state/rice/palette.json (the `pure` or `pure-dark` theme), the cream built in until it's read.
Singleton {
    id: root

    // ── colours ── (named for the light theme: in dark mode "cream" is the charcoal and "ink" the cream)
    // a new palette crossfades in, so switching to dark (or back) glides instead of jumping
    property color cream: pick("bg1", "#edeae4")               // the island, the bar, panels
    property color creamHi: pick("bg0", "#f5f3ef")             // cards on them, popups
    property color well: pick("bg2", "#e3dfd7")                // tracks, pressed, empty dots
    property color line: pick("bg3", "#d6d0c5")                // dividers, outlines
    property color ink: pick("fg", "#2a2520")                  // text and icons
    property color inkSoft: pick("accent2", "#5c544b")
    property color muted: pick("dim", "#8d8478")               // secondary text
    Behavior on cream {
        ColorAnimation {
            duration: 600
        }
    }
    Behavior on creamHi {
        ColorAnimation {
            duration: 600
        }
    }
    Behavior on well {
        ColorAnimation {
            duration: 600
        }
    }
    Behavior on line {
        ColorAnimation {
            duration: 600
        }
    }
    Behavior on ink {
        ColorAnimation {
            duration: 600
        }
    }
    Behavior on inkSoft {
        ColorAnimation {
            duration: 600
        }
    }
    Behavior on muted {
        ColorAnimation {
            duration: 600
        }
    }
    readonly property color shadow: dark ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(0.16, 0.14, 0.12, 0.16)
    // the island and the bar: the cream, a breath see-through (Hyprland frosts behind it)
    readonly property color surface: Qt.alpha(cream, 0.94)

    // (only the pure themes' palettes, `pure` and `pure-dark`: run beside another rice's shell, it keeps its own)
    readonly property bool ours: (data.name ?? "").startsWith("pure")
    readonly property bool dark: data.name === "pure-dark"
    readonly property string wallpaper: ours && data.wallpaper ? data.wallpaper : Quickshell.env("HOME") + "/.config/rice/themes/pure/wallpaper.png"
    // dark mode: the pure-dark theme (the whole rice: the terminal, the borders, the wallpaper too)
    function setDark(on) {
        Quickshell.execDetached(["sh", "-c", '~/.config/rice/rice "$1" --quiet >/dev/null 2>&1', "sh", on ? "pure-dark" : "pure"]);
    }

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
