import QtQuick
import qs.config

// A thick Material slider: the filled part ink, its icon inside it. Drag, click or scroll; moved(v) with 0 … 1.
Item {
    id: root
    property real value: 0
    property string icon: ""
    signal moved(real v)
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.well
    }
    Rectangle {
        height: parent.height
        width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
        radius: height / 2
        color: Theme.ink
        Behavior on width {
            enabled: !area.pressed
            NumberAnimation {
                duration: Theme.fast
                easing.type: Easing.OutCubic
            }
        }
    }
    Sym {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        size: 19
        fill: 1
        color: Theme.cream
    }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(x) {
            return Math.max(0, Math.min(1, x / width));
        }
        onPressed: e => root.moved(at(e.x))
        onPositionChanged: e => {
            if (pressed)
                root.moved(at(e.x));
        }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
