import QtQuick
import Quickshell.Io
import qs.config
import qs.components

// The disk (/): how full as a wavy ring, and how much is free. Every five minutes.
Item {
    id: root
    property real used: 0
    property real free: 0
    Process {
        id: df
        running: true
        command: ["df", "-B1", "--output=size,avail", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = text.trim().split("\n")[1]?.trim().split(/\s+/).map(Number) ?? [];
                if (n.length === 2) {
                    root.used = 1 - n[1] / n[0];
                    root.free = n[1];
                }
            }
        }
    }
    Timer {
        running: true
        interval: 5 * 60 * 1000
        repeat: true
        onTriggered: df.running = true
    }
    WavyRing {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        stroke: 4
        value: root.used
        Column {
            anchors.centerIn: parent
            Sym {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "hard_drive"
                size: Math.max(14, parent.parent.width * 0.2)
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(root.free / 1e9) + " GB"
                font.pixelSize: Math.max(11, parent.parent.width * 0.16)
                font.weight: Font.DemiBold
                elide: Text.ElideNone
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "free"
                font.pixelSize: Theme.small
                color: Theme.muted
                elide: Text.ElideNone
            }
        }
    }
}
