import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

// A focus timer: the time left in the middle of a wavy ring that runs down. ▶ starts and pauses, ↺ resets;
// a click on the minutes (stopped) steps through 5 · 15 · 25 · 45 · 60. A notification when it's done.
Item {
    id: root
    property string uid
    readonly property int minutes: Widgets.find(uid)?.props?.minutes ?? 25
    property int remaining: minutes * 60              // seconds
    property bool running: false
    onMinutesChanged: if (!running)
        remaining = minutes * 60
    Timer {
        running: root.running
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining--;
            if (root.remaining <= 0) {
                root.running = false;
                root.remaining = root.minutes * 60;
                Quickshell.execDetached(["notify-send", "-a", "Focus", "Time's up", root.minutes + " minutes done. Take a breather."]);
            }
        }
    }
    WavyRing {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        stroke: 4
        value: root.remaining / (root.minutes * 60)
        Column {
            anchors.centerIn: parent
            spacing: 2
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.floor(root.remaining / 60) + ":" + String(root.remaining % 60).padStart(2, "0")
                font.pixelSize: Math.max(14, parent.parent.width * 0.2)
                font.weight: Font.DemiBold
                elide: Text.ElideNone
                MouseArea {
                    anchors.fill: parent
                    enabled: !root.running
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const steps = [5, 15, 25, 45, 60];
                        Widgets.setProp(root.uid, "minutes", steps[(steps.indexOf(root.minutes) + 1) % steps.length]);
                    }
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                IconBtn {
                    icon: root.running ? "pause" : "play_arrow"
                    size: 28
                    on: true
                    onClicked: root.running = !root.running
                }
                IconBtn {
                    icon: "replay"
                    size: 28
                    onClicked: {
                        root.running = false;
                        root.remaining = root.minutes * 60;
                    }
                }
            }
        }
    }
}
