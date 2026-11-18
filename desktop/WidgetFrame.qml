import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components
import qs.desktop.widgets

// One widget on the desktop: its card (a rounded cream box, or a shape), its content, and on the workbench
// (Widgets.editing) dragging and resizing. While you drag it follows the pointer exactly; let go and it springs
// into the grid slot the ghost showed (Desktop.qml). It's only ever told its new cells, never rebuilt.
Item {
    id: frame
    required property string uid
    readonly property var w: Widgets.items.find(i => i.uid === uid) ?? null
    readonly property var t: w ? Widgets.types[w.type] : null
    readonly property int cell: Widgets.cell
    readonly property bool editing: Widgets.editing
    readonly property bool selected: editing && Widgets.selected === uid
    readonly property bool shaped: (w?.shape ?? "box") !== "box" || outline.active

    // where it is: its cells, or (dragging / resizing) the pointer's
    property bool held: false
    property real heldX: 0
    property real heldY: 0
    property real heldW: 0
    property real heldH: 0
    x: held ? heldX : (w?.x ?? 0) * cell
    y: held ? heldY : (w?.y ?? 0) * cell
    width: held ? heldW : (w?.w ?? 1) * cell
    height: held ? heldH : (w?.h ?? 1) * cell
    Behavior on x {
        enabled: !frame.held
        SpringAnimation {
            spring: 4
            damping: 0.38
            epsilon: 0.3
        }
    }
    Behavior on y {
        enabled: !frame.held
        SpringAnimation {
            spring: 4
            damping: 0.38
            epsilon: 0.3
        }
    }
    Behavior on width {
        enabled: !frame.held
        SpringAnimation {
            spring: 4
            damping: 0.38
            epsilon: 0.3
        }
    }
    Behavior on height {
        enabled: !frame.held
        SpringAnimation {
            spring: 4
            damping: 0.38
            epsilon: 0.3
        }
    }
    z: held ? 10 : selected ? 5 : 1
    // a little lift while held
    scale: held ? 1.03 : 1
    Behavior on scale {
        SpringAnimation {
            spring: 5
            damping: 0.4
        }
    }

    // arriving: it grows in
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity {
        NumberAnimation {
            duration: Theme.med
        }
    }

    // ── the card ──
    RectangularShadow {
        anchors.fill: parent
        visible: frame.w?.frame ?? true
        radius: frame.shaped ? Math.min(width, height) / 2.3 : 28
        blur: frame.held ? 30 : 16
        offset.y: frame.held ? 10 : 4
        spread: -3
        color: Theme.shadow
    }
    Rectangle {
        anchors.fill: parent
        visible: !frame.shaped
        radius: 28
        color: (frame.w?.frame ?? true) ? Theme.surface : "transparent"
        border.width: frame.editing ? 1.5 : 0
        border.color: frame.selected ? Theme.ink : Qt.alpha(Theme.ink, 0.18)
    }
    ShapeOutline {
        id: outline
        anchors.fill: parent
        visible: frame.shaped
        shape: frame.w?.shape ?? "box"
        angle: (frame.w?.angle ?? 0) / 360
        need: frame.t?.need ?? [0, 0]
        pad: 6
        color: (frame.w?.frame ?? true) ? Theme.surface : "transparent"
        borderWidth: frame.editing ? 1.5 : 0
        borderColor: frame.selected ? Theme.ink : Qt.alpha(Theme.ink, 0.18)
    }

    // ── its content: in a box, padded; in a shape, the biggest box that fits in it ──
    Loader {
        id: content
        anchors.fill: parent
        readonly property real padX: frame.shaped ? (1 - outline.inner[0]) * frame.width / 2 + 6 : 16
        readonly property real padY: frame.shaped ? (1 - outline.inner[1]) * frame.height / 2 + 6 : 14
        anchors.leftMargin: padX
        anchors.rightMargin: padX
        anchors.topMargin: padY
        anchors.bottomMargin: padY
        enabled: !frame.editing                  // on the workbench, a click is for moving it
        // each kind's content is desktop/widgets/<Kind>W.qml; it's told its uid, and reads its settings from that
        source: frame.w ? Qt.resolvedUrl("widgets/" + frame.w.type.charAt(0).toUpperCase() + frame.w.type.slice(1) + "W.qml") : ""
        onLoaded: if (item && "uid" in item)
            item.uid = frame.uid
    }

    // ── on the workbench ──
    // drag it anywhere; the ghost (Desktop) shows the slot it'll land in
    MouseArea {
        anchors.fill: parent
        enabled: frame.editing
        // (a switched-off MouseArea still sets its cursor: the hand only on the workbench)
        cursorShape: !frame.editing ? Qt.ArrowCursor : frame.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property point grab
        onPressed: e => {
            Widgets.selected = frame.uid;
            grab = Qt.point(e.x, e.y);
            frame.heldX = frame.x;
            frame.heldY = frame.y;
            frame.heldW = frame.width;
            frame.heldH = frame.height;
            frame.held = true;
        }
        onPositionChanged: e => {
            if (!pressed)
                return;
            const p = mapToItem(frame.parent, e.x, e.y);
            frame.heldX = Math.max(0, Math.min(frame.parent.width - frame.width, p.x - grab.x));
            frame.heldY = Math.max(0, Math.min(frame.parent.height - frame.height, p.y - grab.y));
        }
        onReleased: frame.land()
    }
    // resize from the corner (in whole cells, never under the kind's smallest)
    Rectangle {
        visible: frame.selected
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -6
        width: 22
        height: 22
        radius: 11
        color: Theme.ink
        border.width: 2
        border.color: Theme.cream
        Sym {
            anchors.centerIn: parent
            text: "open_in_full"
            size: 12
            color: Theme.cream
            rotation: 90
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.SizeFDiagCursor
            onPressed: {
                frame.heldX = frame.x;
                frame.heldY = frame.y;
                frame.heldW = frame.width;
                frame.heldH = frame.height;
                frame.held = true;
            }
            onPositionChanged: e => {
                if (!pressed)
                    return;
                const p = mapToItem(frame, e.x, e.y);
                frame.heldW = Math.max(frame.t.minW * frame.cell, Math.min(frame.parent.width - frame.x, p.x));
                frame.heldH = Math.max(frame.t.minH * frame.cell, Math.min(frame.parent.height - frame.y, p.y));
            }
            onReleased: frame.land()
        }
    }

    // turn the shape (not what's in it): a handle above it, dragged round its middle, every 15°
    Item {
        visible: frame.selected && (frame.w?.shape ?? "box") !== "box"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        width: 26
        height: 36
        Rectangle {                              // the stalk
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: 2
            height: 12
            color: Theme.ink
        }
        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: Theme.ink
            border.width: 2
            border.color: Theme.cream
            Sym {
                anchors.centerIn: parent
                text: "rotate_right"
                size: 15
                color: Theme.cream
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: e => {
                    if (!pressed)
                        return;
                    const p = mapToItem(frame, e.x, e.y);
                    // the angle from its middle to the pointer, up = 0°, clockwise
                    const deg = Math.atan2(p.x - frame.width / 2, frame.height / 2 - p.y) * 180 / Math.PI;
                    const snapped = ((Math.round(deg / 15) * 15) % 360 + 360) % 360;
                    if (snapped !== (frame.w?.angle ?? 0))
                        Widgets.update(frame.uid, { angle: snapped });
                }
            }
        }
    }

    // the slot it'd land in now (the ghost), in cells
    readonly property var slot: held ? [Math.round(heldX / cell), Math.round(heldY / cell), Math.max(t?.minW ?? 1, Math.round(heldW / cell)), Math.max(t?.minH ?? 1, Math.round(heldH / cell))] : null
    function land() {
        const s = slot;
        held = false;
        if (s)
            Widgets.update(uid, { x: s[0], y: s[1], w: s[2], h: s[3] });
    }
}
