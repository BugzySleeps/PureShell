import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

// A month, Monday first: ‹ › page through, today an ink circle, other months' days faint.
Column {
    id: root
    property int offset: 0                       // months from this one
    property int cell: 30
    readonly property date shown: new Date(clock.date.getFullYear(), clock.date.getMonth() + offset, 1)
    spacing: 4

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    RowLayout {
        width: parent.width
        Txt {
            Layout.fillWidth: true
            leftPadding: 6
            text: Qt.formatDate(root.shown, root.width < 280 ? "MMM yyyy" : "MMMM yyyy")   // (short when narrow)
            font.weight: Font.DemiBold
        }
        IconBtn {
            icon: "chevron_left"
            size: 28
            onClicked: root.offset--
        }
        IconBtn {
            icon: "chevron_right"
            size: 28
            onClicked: root.offset++
        }
    }
    Grid {
        columns: 7
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Txt {
                required property string modelData
                width: root.cell
                height: 20
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: Theme.small
                font.weight: Font.DemiBold
                color: Theme.muted
            }
        }
        Repeater {
            model: 42
            Rectangle {
                required property int index
                readonly property int lead: (root.shown.getDay() + 6) % 7
                readonly property date day: new Date(root.shown.getFullYear(), root.shown.getMonth(), index - lead + 1)
                readonly property bool inMonth: day.getMonth() === root.shown.getMonth()
                readonly property bool today: day.toDateString() === clock.date.toDateString()
                width: root.cell
                height: root.cell
                radius: width / 2
                color: today ? Theme.ink : "transparent"
                Txt {
                    anchors.centerIn: parent
                    text: parent.day.getDate()
                    font.pixelSize: 12
                    font.weight: parent.today ? Font.DemiBold : Font.Normal
                    color: parent.today ? Theme.cream : parent.inMonth ? Theme.ink : Theme.line
                }
            }
        }
    }
}
