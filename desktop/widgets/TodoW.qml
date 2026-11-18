import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// A checklist: type and Enter to add, the circle ticks it off, ✕ removes it. Kept as you go.
Item {
    id: root
    property string uid
    readonly property var items: Widgets.find(uid)?.props?.items ?? []
    function put(list) {
        Widgets.setProp(uid, "items", list);
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 6
        Txt {
            text: "To-do"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.items
            boundsBehavior: Flickable.StopAtBounds
            delegate: RowLayout {
                id: row
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 30
                spacing: 8
                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: row.modelData.done ? Theme.ink : "transparent"
                    border.width: 2
                    border.color: Theme.ink
                    Sym {
                        anchors.centerIn: parent
                        visible: row.modelData.done
                        text: "check"
                        size: 14
                        color: Theme.cream
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.put(root.items.map((x, i) => i === row.index ? { text: x.text, done: !x.done } : x))
                    }
                }
                Txt {
                    Layout.fillWidth: true
                    text: row.modelData.text
                    color: row.modelData.done ? Theme.muted : Theme.ink
                    font.strikeout: row.modelData.done
                }
                IconBtn {
                    icon: "close"
                    size: 24
                    iconSize: 14
                    onClicked: root.put(root.items.filter((x, i) => i !== row.index))
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 17
            color: Theme.creamHi
            TextInput {
                id: add
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.ink
                font.family: Theme.font
                font.pixelSize: 13
                clip: true
                onAccepted: {
                    if (text.trim())
                        root.put(root.items.concat([{ text: text.trim(), done: false }]));
                    text = "";
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !parent.text && !parent.activeFocus
                    text: "Add a task…"
                    color: Theme.muted
                }
            }
        }
    }
}
