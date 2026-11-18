import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

// A picture you pick (click it; another click changes it), rounded.
Item {
    id: root
    property string uid
    readonly property string path: Widgets.find(uid)?.props?.path ?? ""
    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: 22
        color: Theme.well
        Image {
            anchors.fill: parent
            source: root.path ? "file://" + root.path : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width * 1.5, height * 1.5)
            asynchronous: true
        }
        Column {
            anchors.centerIn: parent
            visible: !root.path
            spacing: 4
            Sym {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "add_photo_alternate"
                size: 28
                color: Theme.muted
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Choose a photo"
                font.pixelSize: Theme.small
                color: Theme.muted
                elide: Text.ElideNone
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: picker.running = true
    }
    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Choose a photo", "--file-filter=Pictures | *.png *.jpg *.jpeg *.webp *.gif *.PNG *.JPG *.JPEG *.WEBP"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim())
                Widgets.setProp(root.uid, "path", text.trim())
        }
    }
}
