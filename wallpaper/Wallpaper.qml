import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// The wallpaper (the `pure` theme draws its own): a new one fades in over the old.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.cream
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "pure-wallpaper"

            // two pictures: the one showing, and the next fading in on top of it
            property bool flip: false
            readonly property string want: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
            onWantChanged: {
                const next = flip ? a : b;
                next.opacity = 0;
                next.source = want;
            }
            Component.onCompleted: a.source = want

            Image {
                id: a
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                z: win.flip ? 0 : 1
                onStatusChanged: win.ready(a)
                Behavior on opacity {
                    NumberAnimation {
                        duration: 700
                        easing.type: Easing.InOutCubic
                    }
                }
            }
            Image {
                id: b
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                opacity: 0
                z: win.flip ? 1 : 0
                onStatusChanged: win.ready(b)
                Behavior on opacity {
                    NumberAnimation {
                        duration: 700
                        easing.type: Easing.InOutCubic
                    }
                }
            }
            function ready(img) {
                if (img.status !== Image.Ready || img.opacity === 1 || img.source.toString() !== want)
                    return;
                flip = img === b;                    // it goes on top, and fades in
                img.opacity = 1;
            }
        }
    }
}
