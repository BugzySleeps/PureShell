import QtQuick
import Quickshell
import qs.config
import qs.components

// The date in a flower (it starts in one; any shape works): the weekday, the day big, the month.
Item {
    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }
    Column {
        anchors.centerIn: parent
        spacing: -2
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "ddd")
            font.pixelSize: Math.max(10, parent.parent.height * 0.16)
            font.weight: Font.DemiBold
            color: Theme.muted
            elide: Text.ElideNone
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.date.getDate()
            font.pixelSize: Math.max(22, parent.parent.height * 0.52)
            font.weight: Font.Bold
            elide: Text.ElideNone
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "MMM")
            font.pixelSize: Math.max(10, parent.parent.height * 0.16)
            font.weight: Font.DemiBold
            color: Theme.inkSoft
            elide: Text.ElideNone
        }
    }
}
