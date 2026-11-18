import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

// The launcher (SUPER + R): a cream sheet in the middle of the screen. Type to search apps; the first characters
// pick a mode (or click its chip, or Tab through them):
//   =  maths       (Enter copies the answer)
//   :  emoji       (Enter copies it)
//   v  clipboard   (what you've copied, newest first; Enter puts it back on the clipboard)
// ↑ ↓ choose, Enter runs, Esc (or a click anywhere else) closes. Only built while open (shell.qml, Lazy).
PanelWindow {
    id: win
    readonly property bool open: Ui.launcher
    screen: Ui.screen
    implicitWidth: 620
    implicitHeight: 560
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: t > 0.01
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pure-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real t: 0
    Component.onCompleted: {
        t = Qt.binding(() => open ? 1 : 0);
        field.text = Ui.launcherText;
        field.forceActiveFocus();
    }
    onOpenChanged: if (open) {
        field.text = Ui.launcherText;
        field.forceActiveFocus();
    }
    Behavior on t {
        SpringAnimation {
            spring: 3.6
            damping: 0.34
            epsilon: 0.005
        }
    }
    HyprlandFocusGrab {
        active: win.open && grabLater.done
        windows: [win]
        onCleared: Ui.launcher = false
    }
    Timer {
        id: grabLater
        property bool done: false
        running: win.open
        interval: 250
        onTriggered: done = true
    }

    // ── what's typed, and the mode it picks ──
    readonly property var modes: [["", "Apps", "apps"], ["= ", "Maths", "calculate"], [": ", "Emoji", "mood"], ["v ", "Clipboard", "content_paste"]]
    readonly property string mode: field.text.startsWith("=") ? "= " : field.text.startsWith(":") ? ": " : /^v( |$)/.test(field.text) ? "v " : ""
    readonly property string query: (mode ? field.text.slice(mode.trim().length) : field.text).trim().toLowerCase()
    function setMode(prefix) {
        field.text = prefix + query;
        field.forceActiveFocus();
    }

    // every mode gives rows alike: { title, sub, icon (an app's) | sym (a Material Symbol) | glyph (emoji) |
    // image (a picture's path), run }
    readonly property var rows: {
        if (mode === "= ")
            return calcRows();
        if (mode === ": ")
            return emojiRows();
        if (mode === "v ")
            return clipRows();
        return appRows();
    }
    onRowsChanged: list.currentIndex = 0

    // apps: by the start of the name, then of a word in it, then anywhere, then its description, then the
    // letters in order ("ffx" → firefox)
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    function score(a, q) {
        const name = a.name.toLowerCase();
        if (name.startsWith(q))
            return 4;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 3;
        if (name.includes(q))
            return 2;
        if ([a.genericName, a.comment, ...(a.keywords ?? [])].join(" ").toLowerCase().includes(q))
            return 1;
        let i = 0;
        for (const c of name)
            if (c === q[i])
                i++;
        return i === q.length ? 0.5 : 0;
    }
    function appRows() {
        const row = a => ({
                title: a.name,
                sub: a.genericName || a.comment || "",
                icon: a.icon,
                run: () => a.runInTerminal ? Quickshell.execDetached(["kitty", "-e", ...a.command]) : a.execute()
            });
        if (!query)
            return apps.map(row);
        return apps.map(a => ({ a, s: score(a, query) })).filter(r => r.s > 0).sort((x, y) => y.s - x.s).map(r => row(r.a));
    }

    // maths: numbers and + - * / ^ % ( ) only, so nothing else can run
    function calcRows() {
        const expr = query.replace(/\^/g, "**").replace(/x/g, "*");
        if (!expr || !/^[\d\s+\-*/().%]*$/.test(expr))
            return [{ title: "Type a sum", sub: "like 12 * (3 + 4) or 2^10", sym: "calculate", run: () => {} }];
        let v = NaN;
        try {
            v = Function('"use strict"; return (' + expr + ")")();
        } catch (e) {}
        if (!Number.isFinite(v))
            return [];
        const out = String(Math.round(v * 1e10) / 1e10);
        return [{ title: out, sub: "Enter copies it", sym: "equal", run: () => Quickshell.execDetached(["wl-copy", out]) }];
    }

    // emoji (launcher/emoji.tsv, from github.com/github/gemoji, MIT): by its name, its words, its group
    property var emoji: []
    FileView {
        path: Quickshell.shellDir + "/launcher/emoji.tsv"
        onLoaded: win.emoji = text().split("\n").filter(l => l).map(l => l.split("\t"))
    }
    function emojiRows() {
        const q = query;
        const hit = e => !q || e[1].includes(q) || e[2].includes(q) || (e[3] ?? "").includes(q);
        return emoji.filter(hit).slice(0, 80).map(e => ({
                    title: e[2],
                    sub: e[4] ?? "",
                    glyph: e[0],
                    run: () => Quickshell.execDetached(["wl-copy", e[0]])
                }));
    }

    // the clipboard: what's been copied, newest first (Clip)
    function clipRows() {
        return Clip.items.filter(i => !query || (i.kind === "text" && i.text.toLowerCase().includes(query))).map(i => ({
                    title: i.kind === "image" ? "Picture" : i.text.replace(/\s+/g, " ").trim(),
                    sub: i.kind === "image" ? "copied picture" : "",
                    image: i.kind === "image" ? i.path : "",
                    sym: i.kind === "image" ? "" : "content_paste",
                    run: () => Clip.use(i)
                }));
    }

    function runCurrent() {
        const r = rows[list.currentIndex];
        if (!r)
            return;
        Ui.launcher = false;
        r.run();
    }

    // ── the sheet ──
    Item {
        anchors.fill: parent
        anchors.margins: 20
        opacity: Math.min(1, win.t * 1.4)
        scale: 0.94 + 0.06 * win.t
        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 30
            offset.y: 8
            spread: -2
            color: Theme.shadow
        }
        Rectangle {
            id: card
            anchors.fill: parent
            radius: 30
            color: Theme.surface
            border.width: 1
            border.color: Qt.alpha(Theme.ink, 0.06)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // the search
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 26
                    color: Theme.creamHi
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 10
                        Sym {
                            text: win.modes.find(m => m[0] === win.mode)?.[2] ?? "search"
                            size: 22
                        }
                        TextInput {
                            id: field
                            Layout.fillWidth: true
                            color: Theme.ink
                            font.family: Theme.font
                            font.pixelSize: 17
                            selectionColor: Theme.line
                            clip: true
                            Keys.onEscapePressed: Ui.launcher = false
                            Keys.onReturnPressed: win.runCurrent()
                            Keys.onEnterPressed: win.runCurrent()
                            Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                            Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                            Keys.onTabPressed: {
                                const i = win.modes.findIndex(m => m[0] === win.mode);
                                win.setMode(win.modes[(i + 1) % win.modes.length][0]);
                            }
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !parent.text
                                text: "Search apps  ·  = maths  ·  : emoji  ·  v clipboard"
                                color: Theme.muted
                                font.pixelSize: 15
                            }
                        }
                    }
                }

                // the modes
                Row {
                    spacing: 6
                    Repeater {
                        model: win.modes
                        Rectangle {
                            required property var modelData
                            readonly property bool on: win.mode === modelData[0]
                            width: chip.implicitWidth + 30
                            height: 30
                            radius: 15
                            color: on ? Theme.ink : chipArea.containsMouse ? Theme.well : Theme.creamHi
                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.fast
                                }
                            }
                            Row {
                                id: chip
                                anchors.centerIn: parent
                                spacing: 5
                                Sym {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.parent.modelData[2]
                                    size: 16
                                    color: parent.parent.on ? Theme.cream : Theme.ink
                                }
                                Txt {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.parent.modelData[1]
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideNone
                                    color: parent.parent.on ? Theme.cream : Theme.ink
                                }
                            }
                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.setMode(parent.modelData[0])
                            }
                        }
                    }
                }

                // what it found
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: win.rows
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 140
                    highlightResizeDuration: 0
                    highlight: Rectangle {
                        radius: 18
                        color: Theme.well
                    }
                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        width: list.width
                        height: 54
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12
                            Item {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                IconImage {
                                    anchors.fill: parent
                                    visible: !!row.modelData.icon
                                    source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                                }
                                Sym {
                                    anchors.centerIn: parent
                                    visible: !!row.modelData.sym
                                    text: row.modelData.sym ?? ""
                                    size: 22
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: !!row.modelData.glyph
                                    text: row.modelData.glyph ?? ""
                                    font.pixelSize: 24
                                }
                                ClippingRectangle {
                                    anchors.fill: parent
                                    visible: !!row.modelData.image
                                    radius: 8
                                    color: Theme.well
                                    Image {
                                        anchors.fill: parent
                                        source: row.modelData.image ? "file://" + row.modelData.image : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize: Qt.size(68, 68)
                                        asynchronous: true
                                    }
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                Txt {
                                    width: parent.width
                                    text: row.modelData.title
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Txt {
                                    width: parent.width
                                    visible: text !== ""
                                    text: row.modelData.sub ?? ""
                                    font.pixelSize: Theme.small
                                    color: Theme.muted
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = row.index
                            onClicked: win.runCurrent()
                        }
                    }
                    // nothing found
                    Txt {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        text: win.mode === "v " ? "Nothing copied yet" : "Nothing found"
                        color: Theme.muted
                    }
                }
            }
        }
    }
}
