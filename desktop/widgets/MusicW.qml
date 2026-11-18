import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

// What's playing: the cover, the title and artist, how far through (click it to seek), and the controls.
Item {
    id: root
    RowLayout {
        anchors.fill: parent
        spacing: 12
        ClippingRectangle {
            Layout.preferredWidth: Math.min(root.height, 96)
            Layout.preferredHeight: Layout.preferredWidth
            radius: 18
            color: Theme.well
            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(192, 192)
                asynchronous: true
            }
            Sym {
                anchors.centerIn: parent
                visible: !Media.art
                text: "music_note"
                size: 28
                color: Theme.muted
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Txt {
                Layout.fillWidth: true
                text: Media.active ? Media.title : "Nothing playing"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Txt {
                Layout.fillWidth: true
                text: Media.artist
                font.pixelSize: Theme.small
                color: Theme.muted
            }
            Rectangle {                          // how far through
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 4
                radius: 2
                color: Theme.well
                visible: Media.length > 0
                Rectangle {
                    height: parent.height
                    radius: 2
                    width: parent.width * Math.min(1, Media.position / Math.max(1, Media.length))
                    color: Theme.ink
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: e => Media.seek(e.x / width)
                }
            }
            Row {
                spacing: 2
                IconBtn {
                    icon: "skip_previous"
                    size: 30
                    onClicked: Media.previous()
                }
                IconBtn {
                    icon: Media.playing ? "pause" : "play_arrow"
                    size: 30
                    on: true
                    onClicked: Media.toggle()
                }
                IconBtn {
                    icon: "skip_next"
                    size: 30
                    onClicked: Media.next()
                }
            }
        }
    }
}
