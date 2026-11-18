import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

// Quick settings (SUPER + A, or a click on the status): wifi, bluetooth, do not disturb, night light; volume and
// brightness; what's playing.
Sheet {
    id: sheet
    open: Ui.panel === "quick"
    sheetWidth: 360

    RowLayout {
        width: parent.width
        Txt {
            Layout.fillWidth: true
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            font.pixelSize: Theme.big
            font.weight: Font.DemiBold
        }
        IconBtn {
            icon: "lock"
            onClicked: {
                Ui.panel = "";
                Quickshell.execDetached(["loginctl", "lock-session"]);
            }
        }
        IconBtn {
            icon: "power_settings_new"
            onClicked: {
                Ui.panel = "";
                Quickshell.execDetached(["sh", "-c", "command -v hyprshutdown >/dev/null && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]);
            }
        }
    }

    GridLayout {
        width: parent.width
        columns: 2
        rowSpacing: 8
        columnSpacing: 8
        Tile {
            Layout.fillWidth: true
            icon: Net.icon
            label: "Wi-Fi"
            sub: Net.name
            on: Net.enabled && Net.connected
            onClicked: Net.toggle()
        }
        Tile {
            Layout.fillWidth: true
            visible: Bt.available
            icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
            label: "Bluetooth"
            sub: Bt.name
            on: Bt.enabled
            onClicked: Bt.toggle()
        }
        Tile {
            Layout.fillWidth: true
            icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
            label: "Silence"
            sub: Notifs.dnd ? "On" : "Off"
            on: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        Tile {
            Layout.fillWidth: true
            icon: Theme.dark ? "dark_mode" : "light_mode"
            label: "Dark mode"
            sub: Theme.dark ? "On" : "Off"
            on: Theme.dark
            onClicked: Theme.setDark(!Theme.dark)
        }
        Tile {
            Layout.fillWidth: true
            icon: "nightlight"
            label: "Night light"
            sub: Settings.nightMode === "auto" ? "Sunset" : Night.active ? "On" : "Off"
            on: Night.active
            onClicked: Night.toggle()
        }
    }

    Slider {
        width: parent.width
        icon: Audio.icon
        value: Audio.muted ? 0 : Audio.volume
        onMoved: v => Audio.setVolume(v)
    }
    Slider {
        width: parent.width
        visible: Bright.available
        icon: "light_mode"
        value: Bright.value
        onMoved: v => Bright.set(v)
    }

    // what's playing
    Rectangle {
        width: parent.width
        visible: Media.active
        height: 68
        radius: 20
        color: Theme.creamHi
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            ClippingRectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 14
                color: Theme.well
                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(96, 96)
                    asynchronous: true
                }
            }
            Column {
                Layout.fillWidth: true
                Txt {
                    width: parent.width
                    text: Media.title
                    font.weight: Font.DemiBold
                }
                Txt {
                    width: parent.width
                    text: Media.artist
                    font.pixelSize: Theme.small
                    color: Theme.muted
                }
            }
            IconBtn {
                icon: "skip_previous"
                size: 32
                onClicked: Media.previous()
            }
            IconBtn {
                icon: Media.playing ? "pause" : "play_arrow"
                size: 36
                on: true
                onClicked: Media.toggle()
            }
            IconBtn {
                icon: "skip_next"
                size: 32
                onClicked: Media.next()
            }
        }
    }
}
