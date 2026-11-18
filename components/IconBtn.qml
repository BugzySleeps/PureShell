import QtQuick
import qs.config

// A round button with a Material Symbol: a soft well behind it on hover, ink when `on`.
Rectangle {
    id: root
    property string icon: ""
    property bool on: false
    property int size: 34
    property int iconSize: 18
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: on ? Theme.ink : area.containsMouse ? Theme.well : "transparent"
    Behavior on color {
        ColorAnimation {
            duration: Theme.fast
        }
    }
    Sym {
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        fill: root.on ? 1 : 0
        color: root.on ? Theme.cream : Theme.ink
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
