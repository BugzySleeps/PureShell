import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Wifi, volume, the battery (a laptop's), and a dot while there are notifications.
Row {
    id: root
    property int size: 17
    spacing: 8

    Sym {
        anchors.verticalCenter: parent.verticalCenter
        text: Net.icon
        size: root.size
        fill: 1
    }
    Sym {
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.icon
        size: root.size
        fill: 1
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: Audio.toggleMute()
            onWheel: e => Audio.nudge(e.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }
    Row {
        readonly property var bat: UPower.displayDevice
        visible: bat?.isLaptopBattery ?? false
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Sym {
            anchors.verticalCenter: parent.verticalCenter
            readonly property real p: parent.bat?.percentage ?? 0
            readonly property bool charging: parent.bat?.state === UPowerDeviceState.Charging || parent.bat?.state === UPowerDeviceState.FullyCharged
            text: charging ? "battery_charging_full" : ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar", "battery_full"][Math.max(0, Math.min(7, Math.round(p * 7)))]
            size: root.size
            fill: 1
            rotation: 90
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round((parent.bat?.percentage ?? 0) * 100)
            font.pixelSize: Theme.small
            font.weight: Font.Medium
            color: Theme.inkSoft
        }
    }
    Rectangle {
        visible: Notifs.list.length > 0
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 6
        radius: 3
        color: Theme.ink
    }
}
