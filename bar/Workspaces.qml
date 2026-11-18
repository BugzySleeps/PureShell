import QtQuick
import Quickshell.Hyprland
import qs.config

// Workspaces as dots: the one you're on stretches into a pill, ones with windows are ink, empty ones faint.
// Click one to go there; scroll to step through.
Row {
    id: root
    property int dot: 7
    spacing: 5

    readonly property int active: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int count: Math.max(5, active, ...Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id))

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            readonly property int ws: index + 1
            readonly property bool on: ws === root.active
            readonly property bool used: Hyprland.workspaces.values.some(w => w.id === ws && w.toplevels.values.length > 0)
            anchors.verticalCenter: parent.verticalCenter
            width: on ? root.dot * 3 : root.dot
            height: root.dot
            radius: height / 2
            color: on ? Theme.ink : used ? Qt.alpha(Theme.ink, 0.45) : Theme.line
            Behavior on width {
                SpringAnimation {
                    spring: 4
                    damping: 0.35
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Theme.fast
                }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.ws} })`)
            }
        }
    }
    WheelHandler {
        onWheel: e => Hyprland.dispatch(`hl.dsp.focus({ workspace = "${e.angleDelta.y > 0 ? "-1" : "+1"}" })`)
    }
}
