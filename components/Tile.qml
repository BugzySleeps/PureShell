import QtQuick
import qs.config

// A quick setting: an icon, a name and what it's at; ink when on. A click toggles it; `more` (a chevron)
// opens its details, if it has any.
Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool on: false
    signal clicked

    implicitHeight: 62
    radius: 20
    color: on ? Theme.ink : area.containsMouse ? Qt.darker(Theme.creamHi, 1.03) : Theme.creamHi
    Behavior on color {
        ColorAnimation {
            duration: Theme.med
        }
    }
    scale: area.pressed ? 0.97 : 1
    Behavior on scale {
        SpringAnimation {
            spring: 5
            damping: 0.4
        }
    }
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: root.on ? Qt.alpha(Theme.cream, 0.14) : Theme.well
            Sym {
                anchors.centerIn: parent
                text: root.icon
                size: 19
                fill: root.on ? 1 : 0
                color: root.on ? Theme.cream : Theme.ink
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: root.width - 72
            Txt {
                width: parent.width
                text: root.label
                font.weight: Font.DemiBold
                color: root.on ? Theme.cream : Theme.ink
            }
            Txt {
                width: parent.width
                visible: text !== ""
                text: root.sub
                font.pixelSize: Theme.small
                color: root.on ? Qt.alpha(Theme.cream, 0.7) : Theme.muted
            }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
