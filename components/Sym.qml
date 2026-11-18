import QtQuick
import qs.config

// A Material Symbols icon, by its name ("volume_up", "wifi"…): rounded, `fill` 0 (outline) … 1 (filled).
Text {
    id: root
    property real fill: 0
    property int weight: 400
    property int size: 20
    color: Theme.ink
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": root.fill, "wght": root.weight, "opsz": Math.max(20, Math.min(48, root.size)) })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
