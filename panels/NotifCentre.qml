import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.components

// Notifications (SUPER + N, or a click on the dot): kept until you clear them, grouped by app (the app with the
// newest first). Each one: what it says, how long ago, its buttons; ✕ dismisses it.
Sheet {
    id: sheet
    open: Ui.panel === "notifs"
    sheetWidth: 380

    // "how long ago" moves on while it's open
    property int tick: 0
    Timer {
        running: sheet.open
        interval: 30000
        repeat: true
        onTriggered: sheet.tick++
    }

    RowLayout {
        width: parent.width
        Txt {
            Layout.fillWidth: true
            text: "Notifications"
            font.pixelSize: Theme.big
            font.weight: Font.DemiBold
        }
        IconBtn {
            icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
            on: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        IconBtn {
            icon: "clear_all"
            visible: Notifs.list.length > 0
            onClicked: Notifs.clear()
        }
    }

    // nothing
    Column {
        width: parent.width
        visible: Notifs.list.length === 0
        topPadding: 24
        bottomPadding: 24
        spacing: 6
        Sym {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "notifications_paused"
            size: 36
            color: Theme.muted
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "All caught up"
            color: Theme.muted
        }
    }

    Repeater {
        model: Notifs.groups
        Column {
            id: group
            required property var modelData
            width: parent.width
            spacing: 6
            Row {
                spacing: 8
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: Theme.ink
                    IconImage {
                        anchors.centerIn: parent
                        visible: !!group.modelData.icon
                        implicitSize: 14
                        source: group.modelData.icon ? Quickshell.iconPath(group.modelData.icon, true) : ""
                    }
                    Sym {
                        anchors.centerIn: parent
                        visible: !group.modelData.icon
                        text: "notifications"
                        size: 13
                        fill: 1
                        color: Theme.cream
                    }
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: group.modelData.app + (group.modelData.items.length > 1 ? "  ·  " + group.modelData.items.length : "")
                    font.pixelSize: Theme.small
                    font.weight: Font.DemiBold
                    color: Theme.inkSoft
                }
            }
            Repeater {
                model: group.modelData.items
                Rectangle {
                    id: card
                    required property var modelData
                    width: group.width
                    height: col.implicitHeight + 24
                    radius: 18
                    color: Theme.creamHi
                    Column {
                        id: col
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        anchors.rightMargin: 40
                        spacing: 3
                        RowLayout {
                            width: parent.width
                            Txt {
                                Layout.fillWidth: true
                                text: card.modelData.summary
                                font.weight: Font.DemiBold
                            }
                            Txt {
                                text: sheet.tick >= 0 ? Notifs.ago(card.modelData) : ""
                                font.pixelSize: Theme.small
                                color: Theme.muted
                            }
                        }
                        Txt {
                            width: parent.width
                            visible: text !== ""
                            text: (card.modelData.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ")
                            color: Theme.inkSoft
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                        }
                        Flow {
                            width: parent.width
                            visible: card.modelData.actions.length > 0
                            spacing: 6
                            topPadding: 4
                            Repeater {
                                model: card.modelData.actions
                                Rectangle {
                                    required property var modelData
                                    width: act.implicitWidth + 22
                                    height: 28
                                    radius: 14
                                    color: actArea.containsMouse ? Theme.line : Theme.well
                                    Txt {
                                        id: act
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        font.pixelSize: Theme.small
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        id: actArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                    IconBtn {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        icon: "close"
                        size: 28
                        iconSize: 16
                        onClicked: card.modelData.dismiss()
                    }
                }
            }
        }
    }
}
