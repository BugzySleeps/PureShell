import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects
import qs.config
import qs.services

// The top of each screen. Settings.barStyle "island" (the default): just the island, floating a little below
// the edge. "bar": a slim cream bar along the top, the workspaces on the left, the status on the right and
// the island in the middle. Either way windows keep clear of it, and the island grows down over them.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData
            readonly property bool bar: Settings.barStyle === "bar"

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 150                  // room for the island to grow; only what's drawn takes clicks
            exclusiveZone: bar ? Theme.barHeight : Theme.islandHeight + Theme.gap * 2
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: bar ? "pure-bar" : "pure-island"
            mask: Region {
                item: strip
                Region {
                    item: island.shape
                }
            }

            // the bar (bar style)
            RectangularShadow {
                anchors.fill: strip
                visible: win.bar
                blur: 16
                offset.y: 2
                spread: -4
                color: Theme.shadow
            }
            Rectangle {
                id: strip
                width: parent.width
                height: win.bar ? Theme.barHeight : 0
                color: Theme.surface
                visible: win.bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.alpha(Theme.ink, 0.06)
                }
                Workspaces {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                }
                Status {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Island {
                id: island
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.bar ? (Theme.barHeight - Theme.islandHeight) / 2 : Theme.gap
                full: !win.bar
            }
        }
    }
}
