import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// The weather now (Settings.city): its icon, the temperature, what it's like, today's high and low; with room,
// the next three days.
Item {
    id: root
    readonly property var n: Weather.now
    Txt {
        anchors.centerIn: parent
        visible: !root.n
        text: Settings.city ? (Weather.error || "Loading…") : "Set a city in settings"
        color: Theme.muted
    }
    ColumnLayout {
        anchors.fill: parent
        visible: !!root.n
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Sym {
                text: Weather.icon(root.n?.code ?? 0, root.n?.day)
                size: Math.min(44, root.height * 0.42)
                fill: 1
            }
            Column {
                Layout.fillWidth: true
                Txt {
                    text: (root.n?.temp ?? "") + Weather.unit
                    font.pixelSize: Math.min(30, root.height * 0.28)
                    font.weight: Font.DemiBold
                }
                Txt {
                    width: parent.width
                    text: Weather.words(root.n?.code ?? 0) + " · " + (root.n?.hi ?? "") + "° / " + (root.n?.lo ?? "") + "°"
                    font.pixelSize: Theme.small
                    color: Theme.muted
                }
            }
        }
        Row {
            Layout.fillWidth: true
            visible: root.height > 120
            Repeater {
                model: root.n?.days ?? []
                Column {
                    required property var modelData
                    width: root.width / 3
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.modelData.name
                        font.pixelSize: Theme.small
                        font.weight: Font.DemiBold
                        color: Theme.muted
                    }
                    Sym {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Weather.icon(parent.modelData.code, true)
                        size: 20
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.modelData.hi + "° " + parent.modelData.lo + "°"
                        font.pixelSize: Theme.small
                        color: Theme.inkSoft
                    }
                }
            }
        }
    }
}
