import QtQuick
import qs.config
import qs.services
import qs.components

// A note: click and type. Kept as you go.
Item {
    id: root
    property string uid
    readonly property string text: Widgets.find(uid)?.props?.text ?? ""
    Flickable {
        anchors.fill: parent
        contentHeight: edit.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        TextEdit {
            id: edit
            width: parent.width
            text: root.text
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: 14
            wrapMode: TextEdit.Wrap
            selectionColor: Theme.line
            onTextChanged: keep.restart()
        }
    }
    Txt {
        visible: !edit.text && !edit.activeFocus
        text: "Write something…"
        color: Theme.muted
        font.pixelSize: 14
    }
    Timer {
        id: keep
        interval: 600
        onTriggered: if (edit.text !== root.text)
            Widgets.setProp(root.uid, "text", edit.text)
    }
}
