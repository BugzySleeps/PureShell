import QtQuick
import qs.config
import qs.components

// This month, today an ink circle; ‹ › page through.
Item {
    MonthGrid {
        anchors.centerIn: parent
        cell: Math.floor(Math.min(parent.width / 7, (parent.height - 56) / 7))
        width: cell * 7
    }
}
