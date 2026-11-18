import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

// A cream sheet dropping from the top right (quick settings, notifications): it springs down into place, closes
// on Esc or a click anywhere else. Its content goes inside; `open` drives it (Ui.panel), and it's only built
// while open (shell.qml, Lazy).
PanelWindow {
    id: win
    property bool open: false
    property int sheetWidth: 380
    default property alias content: body.data
    readonly property alias body: body

    screen: Ui.screen
    anchors {
        top: true
        right: true
    }
    margins.top: Settings.barStyle === "bar" ? Theme.barHeight + 6 : Theme.islandHeight + Theme.gap * 2 + 2
    margins.right: Theme.gap + 4
    implicitWidth: sheetWidth + 40
    implicitHeight: Math.min(screen.height - margins.top - 20, body.implicitHeight + 72)   // (20 around the card, 16 in it)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: t > 0.01
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pure-panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // built only while open: starts closed and follows `open`, so it springs in all the same
    property real t: 0
    Component.onCompleted: t = Qt.binding(() => open ? 1 : 0)
    Behavior on t {
        SpringAnimation {
            spring: 3.4
            damping: 0.34
            epsilon: 0.005
        }
    }

    HyprlandFocusGrab {
        active: win.open && grabLater.done
        windows: [win]
        onCleared: Ui.panel = ""
    }
    Timer {                                       // (the click that opened it isn't a click away)
        id: grabLater
        property bool done: false
        running: win.open
        interval: 250
        onTriggered: done = true
    }

    Item {
        anchors.fill: parent
        anchors.margins: 20
        opacity: Math.min(1, win.t * 1.4)
        transform: [
            Translate {
                y: (1 - win.t) * -18
            },
            Scale {
                origin.x: card.width
                origin.y: 0
                xScale: 0.94 + 0.06 * win.t
                yScale: 0.94 + 0.06 * win.t
            }
        ]
        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 24
            offset.y: 6
            spread: -2
            color: Theme.shadow
        }
        Rectangle {
            id: card
            anchors.fill: parent
            radius: 28
            color: Theme.surface
            border.width: 1
            border.color: Qt.alpha(Theme.ink, 0.06)
            focus: true
            Keys.onEscapePressed: Ui.panel = ""
            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: body
                    width: parent.width
                    spacing: 12
                }
            }
        }
    }
}
