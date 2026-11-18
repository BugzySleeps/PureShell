import QtQuick
import qs.config
import qs.services
import qs.components

// CPU, memory and temperature as wavy rings (read only while this is on the desktop).
Item {
    id: root
    Component.onCompleted: Sys.wanted++
    Component.onDestruction: Sys.wanted--
    Row {
        anchors.centerIn: parent
        spacing: Math.max(8, (root.width - 3 * ring) / 4)
        readonly property real ring: Math.min(root.height - 22, (root.width - 40) / 3)
        Repeater {
            model: [
                { icon: "memory", label: "CPU", value: Sys.cpu },
                { icon: "memory_alt", label: "Memory", value: Sys.mem },
                { icon: "device_thermostat", label: Sys.temp > 0 ? Math.round(Sys.temp) + "°C" : "Temp", value: Sys.temp / 100, temp: true }
            ]
            Column {
                required property var modelData
                spacing: 2
                WavyRing {
                    width: parent.parent.ring
                    height: width
                    value: parent.modelData.value
                    Sym {
                        anchors.centerIn: parent
                        text: parent.parent.modelData.icon
                        size: Math.max(14, parent.width * 0.3)
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.temp ? parent.modelData.label : parent.modelData.label + " " + Math.round(parent.modelData.value * 100) + "%"
                    font.pixelSize: Theme.small
                    color: Theme.muted
                    elide: Text.ElideNone
                }
            }
        }
    }
}
