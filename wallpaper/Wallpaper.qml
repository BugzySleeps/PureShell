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

            // two pictures: the one showing, and the next fading in on top of it. The next one is the one under
            // (hidden at once, it's covered anyway), loaded, then put on top and faded in. Coming back to a
            // picture it still has loaded works the same: it's ready at once.
            property Image showing: a
            readonly property string want: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
            onWantChanged: {
                const next = showing === a ? b : a;
                next.show = false;
                next.source = want;
                ready(next);
            }
            Component.onCompleted: {
                a.source = want;
                a.show = true;
            }
            function ready(img) {
                if (img === showing || img.status !== Image.Ready || img.source.toString() !== want)
                    return;
                img.z = 1;
                showing.z = 0;
                showing = img;
                img.show = true;
            }

            component Picture: Image {
                property bool show: false
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                opacity: show ? 1 : 0
                Behavior on opacity {
                    enabled: show                 // (fading in; hiding is at once)
                    NumberAnimation {
                        duration: 700
                        easing.type: Easing.InOutCubic
                    }
                }
            }
            Picture {
                id: a
                onStatusChanged: win.ready(a)
            }
            Picture {
                id: b
                onStatusChanged: win.ready(b)
            }
        }
    }
}
