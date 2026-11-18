import QtQuick
import Quickshell
import qs.bar
import qs.wallpaper

// PureShell: creamy white, one warm charcoal ink. The `pure` rice theme runs it (rice pure).
ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }
    }
    Wallpaper {}
    Top {}
}
