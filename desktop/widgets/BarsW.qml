import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Rounded bars moving with the music (cava runs only while something plays and this is on the desktop); a row of
// still dots otherwise. The moving bars are drawn in a little window of their own over the widget: drawn on the
// desktop, every change repainted the whole desktop (and Hyprland the blur over it), half a core while music
// played. On the workbench they're drawn in place, to move with it. ~20 levels a second, no animating between.
Item {
    id: root
    Component.onCompleted: Cava.wanted++
    Component.onDestruction: Cava.wanted--
    readonly property int n: Math.max(6, Math.min(20, Math.floor(width / 14)))
    readonly property bool apart: !Widgets.editing && root.visible && width > 0
    property var levels: []
    Timer {
        running: Media.playing && root.visible
        interval: 50
        repeat: true
        onTriggered: {
            const v = Cava.values, out = [];
            for (let i = 0; i < root.n; i++)
                out.push(v[Math.floor(i * (v.length || 1) / root.n)] ?? 0);
            root.levels = out;
        }
        onRunningChanged: if (!running)
            root.levels = []
    }

    component Bars: Row {
        id: bars
        property real h: root.height
        spacing: (root.width - root.n * bar) / Math.max(1, root.n - 1)
        readonly property real bar: Math.min(10, root.width / root.n * 0.6)
        Repeater {
            model: root.n
            Rectangle {
                required property int index
                readonly property real v: root.levels[index] ?? 0
                anchors.verticalCenter: parent.verticalCenter
                width: bars.bar
                height: Math.max(width, bars.h * v)
                radius: width / 2
                color: Theme.ink
                opacity: 0.35 + 0.65 * Math.min(1, v * 1.4)
            }
        }
    }

    // in place (the workbench)
    Bars {
        anchors.centerIn: parent
        visible: !root.apart
    }
    // apart: a layer window of its own, just the widget's size, over it (a popup still repainted the desktop under
    // it); clicks pass through
    readonly property point at: apart ? root.mapToGlobal(0, 0) : Qt.point(0, 0)
    PanelWindow {
        visible: root.apart
        screen: Quickshell.screens[0]
        anchors {
            top: true
            left: true
        }
        margins.top: root.at.y
        margins.left: root.at.x
        implicitWidth: Math.max(1, root.width)
        implicitHeight: Math.max(1, root.height)
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "pure-live"
        mask: Region {}
        Bars {
            anchors.centerIn: parent
        }
    }
}
