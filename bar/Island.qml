import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

// The island: a cream pill that's the clock at rest, and springs open (overshooting a touch, like something
// soft) for what's happening, then shrinks back:
//   volume / brightness → its icon, a level and the number
//   a new track         → the cover, the title and the artist, a few bars moving with it
//   a notification      → its app, what it says (click: dismiss)
// `full`: on its own (Settings.barStyle "island"), so the workspaces and the status sit in it too; in the bar
// they're the bar's, and it's just the clock.
Item {
    id: root
    property bool full: true
    readonly property alias shape: pill

    // ── what it's showing ──
    property string mode: "rest"                 // rest · level · track · notify
    property string levelIcon: ""
    property real level: 0
    property var note: null
    property bool armed: false                   // not for the values settling as the shell starts
    Timer {
        running: true
        interval: 1500
        onTriggered: root.armed = true
    }
    function show(m, ms) {
        mode = m;
        back.interval = ms;
        back.restart();
    }
    Timer {
        id: back
        onTriggered: if (hover.hovered)
            restart();
        else
            root.mode = "rest"
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.levelOf(Audio.icon, Audio.volume);
        }
        function onMutedChanged() {
            root.levelOf(Audio.icon, Audio.muted ? 0 : Audio.volume);
        }
    }
    Connections {
        target: Bright
        function onValueChanged() {
            root.levelOf("light_mode", Bright.value);
        }
    }
    function levelOf(icon, v) {
        if (!armed)
            return;
        levelIcon = icon;
        level = v;
        show("level", 1400);
    }
    Connections {
        target: Media
        function onTrackKeyChanged() {
            if (root.armed && Media.player?.trackTitle && root.mode !== "notify")
                trackLater.restart();
        }
    }
    Timer {
        id: trackLater                           // the title and the cover arrive in pieces: wait for them
        interval: 350
        onTriggered: root.show("track", 3200)
    }
    Connections {
        target: Notifs
        function onArrived(n) {
            root.note = n;
            root.show("notify", 5000);
        }
    }
    // the bars only run while the track's showing
    property bool wantsBars: mode === "track"
    onWantsBarsChanged: Cava.wanted += wantsBars ? 1 : -1

    // ── its size, by what it shows ──
    readonly property real restW: restRow.implicitWidth + 32
    readonly property var target: ({
            rest: [restW, Theme.islandHeight],
            level: [300, 46],
            track: [380, 72],
            notify: [400, noteCol.implicitHeight + 28]
        })[mode]
    implicitWidth: 420
    implicitHeight: 120

    RectangularShadow {
        anchors.fill: pill
        radius: pill.radius
        offset.y: 3
        blur: 18
        spread: -2
        color: Theme.shadow
    }
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.target[0]
        height: root.target[1]
        radius: Math.min(height / 2, 26)
        color: Theme.surface
        border.width: 1
        border.color: Qt.alpha(Theme.ink, 0.06)
        clip: true
        // the stretch: springs, so it overshoots a little and settles
        Behavior on width {
            SpringAnimation {
                spring: 3.6
                damping: 0.3
                epsilon: 0.5
            }
        }
        Behavior on height {
            SpringAnimation {
                spring: 3.6
                damping: 0.3
                epsilon: 0.5
            }
        }

        HoverHandler {
            id: hover
        }

        // ── at rest: the clock (and in island mode, the workspaces either side of it and the status) ──
        RowLayout {
            id: restRow
            anchors.centerIn: parent
            spacing: 14
            opacity: root.mode === "rest" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fast
                }
            }
            Workspaces {
                visible: root.full
            }
            Row {
                spacing: 6
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(clock.date, "hh:mm")
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDate(clock.date, "ddd d")
                    color: Theme.muted
                    font.weight: Font.Medium
                }
                Rectangle {                      // something's playing
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Media.playing
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.ink
                }
            }
            Status {
                visible: root.full
            }
        }

        // ── a level: volume or brightness ──
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 18
            spacing: 12
            opacity: root.mode === "level" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fast
                }
            }
            Sym {
                text: root.levelIcon
                fill: 1
                size: 20
            }
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Theme.well
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.level))
                    height: parent.height
                    radius: 3
                    color: Theme.ink
                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.fast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
            Txt {
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.level * 100)
                font.weight: Font.DemiBold
            }
        }

        // ── a new track ──
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            opacity: root.mode === "track" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fast
                }
            }
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
                Sym {
                    anchors.centerIn: parent
                    visible: !Media.art
                    text: "music_note"
                    color: Theme.muted
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 2
                Txt {
                    width: parent.width
                    text: Media.title
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Txt {
                    width: parent.width
                    text: Media.artist
                    color: Theme.muted
                }
            }
            Row {                                // a few bars, moving with it
                spacing: 3
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 4 + 18 * (Cava.values[index * 2] ?? 0)
                        radius: 2
                        color: Theme.ink
                        Behavior on height {
                            NumberAnimation {
                                duration: 90
                            }
                        }
                    }
                }
            }
        }

        // ── a notification ──
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            opacity: root.mode === "notify" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fast
                }
            }
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop
                radius: 19
                color: Theme.ink
                IconImage {
                    anchors.centerIn: parent
                    visible: !!root.note?.appIcon
                    implicitSize: 22
                    source: root.note?.appIcon ? Quickshell.iconPath(root.note.appIcon, true) : ""
                }
                Sym {
                    anchors.centerIn: parent
                    visible: !root.note?.appIcon
                    text: "notifications"
                    fill: 1
                    size: 20
                    color: Theme.cream
                }
            }
            Column {
                id: noteCol
                Layout.fillWidth: true
                spacing: 2
                Txt {
                    width: parent.width
                    text: (root.note?.appName || "notice").toLowerCase()
                    font.pixelSize: Theme.small
                    font.weight: Font.Medium
                    color: Theme.muted
                }
                Txt {
                    width: parent.width
                    text: root.note?.summary ?? ""
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Txt {
                    width: parent.width
                    visible: text !== ""
                    text: (root.note?.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ")
                    color: Theme.inkSoft
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: root.mode === "notify"
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.note?.dismiss();
                root.mode = "rest";
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
