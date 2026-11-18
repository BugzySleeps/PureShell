import QtQuick
import Quickshell
import qs.bar
import qs.wallpaper
import qs.panels
import qs.services
import qs.components
import qs.launcher
import qs.desktop

// PureShell: creamy white, one warm charcoal ink. The `pure` rice theme runs it (rice pure).
ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }
    }
    // always on: the night light (auto switches it at sunset), the clipboard (keeps what's copied)
    readonly property var running: [Night, Clip]

    Wallpaper {}
    Desktop {}
    Top {}
    // only built while open (components/Lazy.qml)
    Lazy {
        want: Ui.panel === "quick"
        QuickSettings {}
    }
    Lazy {
        want: Ui.panel === "notifs"
        NotifCentre {}
    }
    Lazy {
        want: Ui.launcher
        Launcher {}
    }
}
