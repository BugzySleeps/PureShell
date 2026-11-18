import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components
import "../components/Shapes.js" as Shapes

// The desktop: the widgets, over the wallpaper and under the windows. SUPER + W turns it into the workbench: it
// rises over everything, the windows dim behind a cream veil, the grid shows, and:
//   drag a widget to move it, its corner to resize it: a ghost shows the cells it'll land in, and it springs
//   there when you let go
//   the drawer at the bottom: every kind of widget (click one, or drag it out to where you want it), and for the
//   one you've picked its shape, a card or bare, and remove
// Esc, Done or SUPER + W again puts it back.
PanelWindow {
    id: win
    screen: Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: Widgets.editing ? WlrLayer.Top : WlrLayer.Bottom
    WlrLayershell.namespace: "pure-desktop"
    WlrLayershell.keyboardFocus: Widgets.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

    readonly property int cell: Widgets.cell
    onWidthChanged: Widgets.cols = Math.floor(width / cell)
    onHeightChanged: Widgets.rows = Math.floor(height / cell)
    property real bench: Widgets.editing ? 1 : 0
    Behavior on bench {
        NumberAnimation {
            duration: Theme.med
            easing.type: Easing.OutCubic
        }
    }

    // the veil over the windows, and the grid
    Rectangle {
        anchors.fill: parent
        color: Theme.cream
        opacity: 0.72 * win.bench
        visible: opacity > 0
    }
    Canvas {
        id: grid
        anchors.fill: parent
        opacity: win.bench
        visible: opacity > 0
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const g = getContext("2d");
            g.reset();
            g.fillStyle = Qt.alpha(Theme.ink, 0.22);
            for (let x = 0; x <= width; x += win.cell)
                for (let y = 0; y <= height; y += win.cell) {
                    g.beginPath();
                    g.arc(x, y, 1.4, 0, 2 * Math.PI);
                    g.fill();
                }
        }
    }

    Item {
        id: board
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Widgets.toggleEdit()

        // a click on nothing: none picked
        MouseArea {
            anchors.fill: parent
            enabled: Widgets.editing
            onClicked: Widgets.selected = ""
        }

        // the ghost: where the held widget will land
        Rectangle {
            id: ghost
            readonly property var held: frames.held()
            visible: !!held
            x: (held?.slot?.[0] ?? 0) * win.cell
            y: (held?.slot?.[1] ?? 0) * win.cell
            width: (held?.slot?.[2] ?? 1) * win.cell
            height: (held?.slot?.[3] ?? 1) * win.cell
            radius: 28
            color: Qt.alpha(Theme.ink, 0.06)
            border.width: 2
            border.color: Qt.alpha(Theme.ink, 0.35)
            Behavior on x {
                SpringAnimation {
                    spring: 5
                    damping: 0.45
                }
            }
            Behavior on y {
                SpringAnimation {
                    spring: 5
                    damping: 0.45
                }
            }
            Behavior on width {
                SpringAnimation {
                    spring: 5
                    damping: 0.45
                }
            }
            Behavior on height {
                SpringAnimation {
                    spring: 5
                    damping: 0.45
                }
            }
        }

        Repeater {
            id: frames
            // by uid: a widget changing (moved, resized, reshaped) is told so, never rebuilt
            model: ScriptModel {
                values: Widgets.items.map(w => w.uid)
            }
            function held() {
                for (let i = 0; i < count; i++)
                    if (itemAt(i)?.held)
                        return itemAt(i);
                return null;
            }
            WidgetFrame {
                required property string modelData
                uid: modelData
            }
        }
    }

    // ── the hint at the top ──
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 14 + (1 - win.bench) * -60
        visible: win.bench > 0
        width: hint.implicitWidth + 24
        height: 44
        radius: 22
        color: Theme.surface
        Row {
            id: hint
            anchors.centerIn: parent
            spacing: 12
            Sym {
                anchors.verticalCenter: parent.verticalCenter
                text: "handyman"
                size: 20
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: "Workbench  ·  drag to move, the corner to resize"
                font.weight: Font.DemiBold
                elide: Text.ElideNone
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: done.implicitWidth + 26
                height: 30
                radius: 15
                color: Theme.ink
                Txt {
                    id: done
                    anchors.centerIn: parent
                    text: "Done"
                    font.weight: Font.DemiBold
                    color: Theme.cream
                    elide: Text.ElideNone
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Widgets.toggleEdit()
                }
            }
        }
    }

    // ── the drawer ──
    Item {
        id: drawer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        // lowered (its tab, or while a widget's held): only the tab shows, so the space under it is free to use
        property bool lowered: false
        readonly property bool down: lowered || !!ghost.held
        property real sink: down ? height + 18 : 0     // (all of it under the edge: the tab sits on the bottom)
        Behavior on sink {
            SpringAnimation {
                spring: 3.6
                damping: 0.36
                epsilon: 0.5
            }
        }
        anchors.bottomMargin: 18 - sink - (1 - win.bench) * 260
        visible: win.bench > 0
        width: Math.max(kinds.implicitWidth, tools.implicitWidth) + 32
        height: col.implicitHeight + 28
        readonly property var picked: Widgets.find(Widgets.selected)
        Behavior on width {
            SpringAnimation {
                spring: 4
                damping: 0.4
            }
        }
        RectangularShadow {
            anchors.fill: parent
            radius: 28
            blur: 26
            offset.y: 6
            spread: -2
            color: Theme.shadow
        }
        Rectangle {
            anchors.fill: parent
            radius: 28
            color: Theme.surface
            border.width: 1
            border.color: Qt.alpha(Theme.ink, 0.06)
        }
        // the tab: lowers it, raises it
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: -1
            width: tabRow.implicitWidth + 28
            height: 30
            radius: 15
            color: tabArea.containsMouse ? Theme.creamHi : Theme.surface
            Row {
                id: tabRow
                anchors.centerIn: parent
                spacing: 4
                Sym {
                    anchors.verticalCenter: parent.verticalCenter
                    text: drawer.down ? "keyboard_arrow_up" : "keyboard_arrow_down"
                    size: 18
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: drawer.down ? "Widgets" : "Lower"
                    font.pixelSize: Theme.small
                    font.weight: Font.DemiBold
                    elide: Text.ElideNone
                }
            }
            MouseArea {
                id: tabArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: drawer.lowered = !drawer.lowered
            }
        }
        Column {
            id: col
            anchors.centerIn: parent
            spacing: 12
            // every kind: click to add, or drag it out to where it should go
            Grid {
                id: kinds
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 8
                spacing: 8
                Repeater {
                    model: Widgets.order
                    Rectangle {
                        id: kind
                        required property string modelData
                        readonly property var t: Widgets.types[modelData]
                        width: 80
                        height: 70
                        radius: 20
                        color: kindArea.containsMouse ? Theme.well : Theme.creamHi
                        scale: kindArea.pressed ? 0.95 : 1
                        Behavior on scale {
                            SpringAnimation {
                                spring: 5
                                damping: 0.4
                            }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Sym {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: kind.t.icon
                                size: 24
                            }
                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: kind.t.title
                                font.pixelSize: Theme.small
                                font.weight: Font.DemiBold
                                elide: Text.ElideNone
                            }
                        }
                        MouseArea {
                            id: kindArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            property point from
                            onPressed: e => from = Qt.point(e.x, e.y)
                            onReleased: e => {
                                const p = mapToItem(board, e.x, e.y);
                                const dragged = Math.hypot(e.x - from.x, e.y - from.y) > 24;
                                // dragged out: there (its middle under the pointer); clicked: in the middle
                                const cx = dragged ? p.x : board.width / 2, cy = dragged ? p.y : board.height / 2 - 60;
                                Widgets.add(kind.modelData, Math.round(cx / win.cell - kind.t.w / 2), Math.round(cy / win.cell - kind.t.h / 2));
                            }
                        }
                    }
                }
            }
            // the picked one: its shape, a card or bare, remove
            Row {
                id: tools
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !!drawer.picked
                spacing: 6
                Repeater {
                    model: ["box", "circle", "squircle", "cookie4", "cookie6", "cookie9", "cookie12", "clover4", "flower", "sunny", "puffy", "arch", "gem"]
                    Rectangle {
                        id: pick
                        required property string modelData
                        readonly property bool on: (drawer.picked?.shape ?? "box") === modelData
                        width: 34
                        height: 34
                        radius: 10
                        color: on ? Theme.ink : pickArea.containsMouse ? Theme.well : "transparent"
                        Item {
                            anchors.fill: parent
                            anchors.margins: 6
                            Rectangle {                  // the box, as itself
                                anchors.fill: parent
                                visible: pick.modelData === "box"
                                radius: 6
                                color: pick.on ? Theme.cream : Theme.inkSoft
                            }
                            ShapeOutline {
                                anchors.fill: parent
                                visible: pick.modelData !== "box"
                                shape: pick.modelData === "box" ? "squircle" : pick.modelData
                                color: pick.on ? Theme.cream : Theme.inkSoft
                            }
                        }
                        MouseArea {
                            id: pickArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Widgets.update(drawer.picked.uid, { shape: pick.modelData })
                        }
                    }
                }
                Rectangle {
                    width: 1
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.line
                }
                // turn the shape, 15° at a time (a box doesn't turn)
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (drawer.picked?.shape ?? "box") !== "box"
                    icon: "rotate_left"
                    onClicked: Widgets.update(drawer.picked.uid, { angle: (((drawer.picked.angle ?? 0) - 15) % 360 + 360) % 360 })
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (drawer.picked?.shape ?? "box") !== "box"
                    width: 34
                    horizontalAlignment: Text.AlignHCenter
                    text: (drawer.picked?.angle ?? 0) + "°"
                    font.weight: Font.DemiBold
                    elide: Text.ElideNone
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (drawer.picked?.shape ?? "box") !== "box"
                    icon: "rotate_right"
                    onClicked: Widgets.update(drawer.picked.uid, { angle: ((drawer.picked.angle ?? 0) + 15) % 360 })
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: (drawer.picked?.frame ?? true) ? "crop_square" : "check_box_outline_blank"
                    on: drawer.picked?.frame ?? true
                    onClicked: Widgets.update(drawer.picked.uid, { frame: !drawer.picked.frame })
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "delete"
                    onClicked: Widgets.remove(drawer.picked.uid)
                }
            }
        }
    }
}
