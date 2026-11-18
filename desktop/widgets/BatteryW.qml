import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.components

// The battery: how full as a wavy ring, the number in it, a bolt while it charges.
Item {
    id: root
    readonly property var bat: UPower.displayDevice
    readonly property real p: bat?.percentage ?? 0
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
    WavyRing {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        stroke: 4
        value: root.p
        Column {
            anchors.centerIn: parent
            Sym {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.charging ? "bolt" : "battery_full"
                size: Math.max(14, parent.parent.width * 0.2)
                fill: 1
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(root.p * 100) + "%"
                font.pixelSize: Math.max(12, parent.parent.width * 0.2)
                font.weight: Font.DemiBold
                elide: Text.ElideNone
            }
        }
    }
}
