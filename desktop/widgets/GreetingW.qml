import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.config
import qs.services
import qs.components

// "Good evening, Bugzy": your picture (~/.face) or your initial, the date, and the weather in a word.
Item {
    id: root
    readonly property string who: {
        const u = Quickshell.env("USER") || "";
        return u.charAt(0).toUpperCase() + u.slice(1);
    }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property int h: clock.date.getHours()
    readonly property string part: h < 5 ? "night" : h < 12 ? "morning" : h < 17 ? "afternoon" : h < 22 ? "evening" : "night"
    RowLayout {
        anchors.fill: parent
        spacing: 14
        ClippingRectangle {
            Layout.preferredWidth: Math.min(root.height, 64)
            Layout.preferredHeight: Layout.preferredWidth
            radius: width / 2
            color: Theme.ink
            // ~/.face, if there is one
            Process {
                running: true
                command: ["test", "-f", Quickshell.env("HOME") + "/.face"]
                onExited: code => face.source = code === 0 ? "file://" + Quickshell.env("HOME") + "/.face" : ""
            }
            Image {
                id: face
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(128, 128)
                asynchronous: true
            }
            Txt {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: root.who.charAt(0)
                font.pixelSize: parent.width * 0.45
                font.weight: Font.DemiBold
                color: Theme.cream
                elide: Text.ElideNone
            }
        }
        Column {
            Layout.fillWidth: true
            spacing: 2
            Txt {
                width: parent.width
                text: (root.part === "night" ? "Good night" : "Good " + root.part) + ", " + root.who
                font.pixelSize: Math.min(22, root.height * 0.32)
                font.weight: Font.DemiBold
            }
            Txt {
                width: parent.width
                text: Qt.formatDate(clock.date, "dddd, MMMM d") + (Weather.now ? "  ·  " + Weather.words(Weather.now.code).toLowerCase() + ", " + Weather.now.temp + "°" : "")
                color: Theme.muted
            }
        }
    }
}
