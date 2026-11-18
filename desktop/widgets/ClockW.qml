import QtQuick
import Quickshell
import qs.config
import qs.components

// The time, big, and the date under it; both scale with the widget.
Item {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    Column {
        anchors.centerIn: parent
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "hh:mm")
            font.pixelSize: Math.max(24, Math.min(parent.parent.height * 0.62, parent.parent.width * 0.3))
            font.weight: Font.DemiBold
            elide: Text.ElideNone
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd, MMMM d")
            font.pixelSize: Math.max(11, Math.min(15, parent.parent.height * 0.14))
            color: Theme.muted
            elide: Text.ElideNone
        }
    }
}
