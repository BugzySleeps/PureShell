import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

// The time of day as a soft sky: peach at dawn, pale blue by day, rose at dusk, slate at night, the sun (or
// the moon) along its arc. Once a minute.
Item {
    id: root
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property real hour: clock.date.getHours() + clock.date.getMinutes() / 60
    readonly property bool day: hour >= 6.5 && hour < 19
    // how far across: the sun from 6:30 to 19:00, the moon from 19:00 to 6:30
    readonly property real across: day ? (hour - 6.5) / 12.5 : ((hour + 24 - 19) % 24) / 11.5
    readonly property var sky: hour < 5 || hour >= 21 ? ["#5d6476", "#3f4554"] : hour < 8 ? ["#f0cdb5", "#e8b9a4"]
        : hour < 17 ? ["#cfdbe3", "#e8e4dc"] : ["#e7b7ae", "#c99aa6"]
    readonly property bool dark: hour < 5 || hour >= 21

    Rectangle {
        anchors.fill: parent
        anchors.margins: -8
        radius: 22
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.sky[0]
            }
            GradientStop {
                position: 1
                color: root.sky[1]
            }
        }
        // the sun or the moon on its arc
        Rectangle {
            readonly property real a: Math.PI * (1 - root.across)
            width: 22
            height: 22
            radius: 11
            color: root.day ? "#fff4d6" : "#eef0f5"
            x: parent.width / 2 + Math.cos(a) * (parent.width / 2 - 24) - width / 2
            y: parent.height - 14 - Math.sin(a) * (parent.height - 34) - height / 2
            Behavior on x {
                NumberAnimation {
                    duration: Theme.slow
                }
            }
        }
        Column {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 14
            Txt {
                text: root.hour < 5 ? "Night" : root.hour < 8 ? "Sunrise" : root.hour < 17 ? "Day" : root.hour < 21 ? "Sunset" : "Night"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: root.dark ? "#f2f0ec" : Theme.ink
                elide: Text.ElideNone
            }
            Txt {
                text: Qt.formatTime(clock.date, "hh:mm") + (Weather.now ? "  ·  " + Weather.now.temp + "°" : "")
                font.pixelSize: Theme.small
                color: root.dark ? "#cfd3dc" : Theme.inkSoft
                elide: Text.ElideNone
            }
        }
    }
}
