import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
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
    readonly property alias tab: tab

    // ── what it's showing ──
    property string mode: "rest"                 // rest · level · track · notify · claude
    property bool claudeNeeds: false
    property string claudeProject: ""
    property string claudeText: ""
    property string levelIcon: ""
    property real level: 0
    property var note: null
    property bool armed: false                   // not for the values settling as the shell starts
    Timer {
        running: true
        interval: 1500
        onTriggered: root.armed = true
    }
    // the Today card (a click on the clock, Ui.panel "today"): the island opens into it, and stays until closed;
    // what happens meanwhile doesn't take it over
    readonly property bool today: (Ui.panel === "today" || Ui.panel === "music") && QsWindow.window?.screen === Ui.screen
    readonly property string shown: today ? "today" : mode
    onTodayChanged: {
        Sys.wanted += today ? 1 : -1;
        if (today) {
            month.offset = 0;
            page = Ui.panel === "music" ? "music" : "today";   // (panel toggle music: straight to the player)
        }
    }
    // its two pages: "today" (the calendar and all) and "music" (the player), the tab on its right switching
    property string page: "today"

    // the player's position, moving smoothly between Media's once-a-second readings; and the wave's drift
    property real played: Media.position
    property real phase: 0
    Connections {
        target: Media
        function onPositionChanged() {
            root.played = Media.position;
        }
    }
    FrameAnimation {
        running: root.today && root.page === "music" && Media.playing
        onTriggered: {
            root.played = Math.min(Media.length, root.played + frameTime);
            root.phase += frameTime * 5;
        }
    }
    function show(m, ms) {
        if (today)
            return;
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
        target: Ui
        function onClaude(kind, project, text) {
            if (root.QsWindow.window?.screen !== Ui.screen)
                return;
            root.claudeNeeds = kind === "needs";
            root.claudeProject = project;
            root.claudeText = text || (root.claudeNeeds ? "needs you" : "done");
            root.show("claude", root.claudeNeeds ? 8000 : 5000);
        }
    }
    Connections {
        target: Notifs
        function onArrived(n) {
            root.note = n;
            root.show("notify", 5000);
        }
    }
    // the bars only run while the track's showing
    property bool wantsBars: shown === "track"
    onWantsBarsChanged: Cava.wanted += wantsBars ? 1 : -1

    // ── its size, by what it shows ──
    readonly property real restW: restRow.implicitWidth + 32
    readonly property var target: today ? [380, (page === "music" ? musicCol.implicitHeight : todayCol.implicitHeight) + 36] : ({
            rest: [restW, Theme.islandHeight],
            level: [300, 46],
            track: [380, 72],
            notify: [400, noteCol.implicitHeight + 28],
            claude: [320, 58]
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
    // the tab on the Today card's right: the player, and back (under the card's edge, so it reads as part of it)
    Rectangle {
        id: tab
        visible: root.today
        x: pill.x + pill.width - 14
        y: pill.y + Math.min(84, pill.height / 2 - height / 2)
        width: 44
        height: 58
        radius: 18
        color: tabArea.containsMouse ? Theme.creamHi : Theme.surface
        border.width: 1
        border.color: Qt.alpha(Theme.ink, 0.06)
        opacity: root.today ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.med
            }
        }
        Sym {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 7
            text: root.page === "music" ? "calendar_month" : "music_note"
            size: 20
            fill: root.page === "music" ? 0 : 1
        }
        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.page = root.page === "music" ? "today" : "music"
        }
    }
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.target[0]
        height: root.target[1]
        radius: Math.min(height / 2, root.today ? 30 : 26)
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
            opacity: root.shown === "rest" ? 1 : 0
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
                TapHandler {                     // a click on the clock opens the Today card
                    onTapped: Ui.toggle("today")
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(clock.date, "hh:mm")
                    elide: Text.ElideNone
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDate(clock.date, "ddd d")
                    elide: Text.ElideNone
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
            opacity: root.shown === "level" ? 1 : 0
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
            opacity: root.shown === "track" ? 1 : 0
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
                        // (only while the track's showing: hidden, it would still animate, and keep the island
                        // repainting every frame while music played)
                        height: root.shown === "track" ? 4 + 18 * (Cava.values[index * 2] ?? 0) : 4
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
            opacity: root.shown === "notify" ? 1 : 0
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

        // ── Claude Code: done, or waiting on you ──
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            opacity: root.shown === "claude" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fast
                }
            }
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: root.claudeNeeds ? Theme.ink : Theme.well
                Txt {
                    anchors.centerIn: parent
                    text: "✻"
                    font.pixelSize: 18
                    color: root.claudeNeeds ? Theme.cream : Theme.ink
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 1
                Txt {
                    width: parent.width
                    text: "claude" + (root.claudeProject ? "  ·  " + root.claudeProject : "")
                    font.pixelSize: Theme.small
                    font.weight: Font.Medium
                    color: Theme.muted
                }
                Txt {
                    width: parent.width
                    text: root.claudeText
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
            }
        }

        // ── the Today card: the time, the weather, the month, the machine ──
        Column {
            id: todayCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.page === "music" ? -60 : 0
            Behavior on anchors.horizontalCenterOffset {
                SpringAnimation {
                    spring: 4
                    damping: 0.4
                }
            }
            y: 18
            width: 344
            spacing: 14
            opacity: root.today && root.page === "today" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.med
                }
            }
            RowLayout {
                width: parent.width
                Txt {
                    text: Qt.formatTime(clock.date, "hh:mm")
                    font.pixelSize: 40
                    font.weight: Font.DemiBold
                }
                Column {
                    Layout.leftMargin: 8
                    Layout.fillWidth: true
                    Txt {
                        text: Qt.formatDate(clock.date, "dddd")
                        font.weight: Font.DemiBold
                    }
                    Txt {
                        text: Qt.formatDate(clock.date, "MMMM d")
                        color: Theme.muted
                    }
                }
                Column {                         // the weather now
                    visible: !!Weather.now
                    Row {
                        anchors.right: parent.right
                        spacing: 4
                        Sym {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.icon(Weather.now?.code ?? 0, Weather.now?.day)
                            size: 24
                            fill: 1
                        }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (Weather.now?.temp ?? "") + "°"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                    }
                    Txt {
                        anchors.right: parent.right
                        text: Weather.words(Weather.now?.code ?? 0) + " · " + (Weather.now?.hi ?? "") + "° / " + (Weather.now?.lo ?? "") + "°"
                        font.pixelSize: Theme.small
                        color: Theme.muted
                    }
                }
            }
            Row {                                // the next three days
                visible: !!Weather.now
                width: parent.width
                Repeater {
                    model: Weather.now?.days ?? []
                    Rectangle {
                        required property var modelData
                        width: parent.width / 3 - 4
                        height: 40
                        radius: 14
                        color: Theme.creamHi
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.modelData.name
                                font.pixelSize: Theme.small
                                font.weight: Font.DemiBold
                            }
                            Sym {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Weather.icon(parent.parent.modelData.code, true)
                                size: 18
                            }
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.modelData.hi + "°"
                                font.pixelSize: Theme.small
                                color: Theme.inkSoft
                            }
                        }
                    }
                }
                spacing: 6
            }
            MonthGrid {
                id: month
                anchors.horizontalCenter: parent.horizontalCenter
                cell: 46
                width: cell * 7
            }
            Row {                                // the machine, as wavy rings
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 28
                Repeater {
                    model: [
                        { icon: "memory", label: "CPU", value: Sys.cpu },
                        { icon: "memory_alt", label: "Memory", value: Sys.mem },
                        { icon: "battery_full", label: "Battery", value: UPower.displayDevice?.percentage ?? 0 }
                    ]
                    Column {
                        required property var modelData
                        spacing: 4
                        WavyRing {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 58
                            height: 58
                            value: parent.modelData.value
                            Sym {
                                anchors.centerIn: parent
                                text: parent.parent.modelData.icon
                                size: 20
                            }
                        }
                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.modelData.label + " " + Math.round(parent.modelData.value * 100) + "%"
                            font.pixelSize: Theme.small
                            color: Theme.muted
                        }
                    }
                }
            }
        }

        // ── the player (the Today card's second page) ──
        Column {
            id: musicCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.page === "music" ? 0 : 60
            Behavior on anchors.horizontalCenterOffset {
                SpringAnimation {
                    spring: 4
                    damping: 0.4
                }
            }
            y: 18
            width: 344
            spacing: 12
            opacity: root.today && root.page === "music" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.med
                }
            }
            ClippingRectangle {
                width: parent.width
                height: 220
                radius: 24
                color: Theme.well
                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(688, 440)
                    asynchronous: true
                }
                Sym {
                    anchors.centerIn: parent
                    visible: !Media.art
                    text: "music_note"
                    size: 56
                    color: Theme.muted
                }
            }
            Column {
                width: parent.width
                spacing: 2
                Txt {
                    width: parent.width
                    text: Media.active ? Media.title : "Nothing playing"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                Txt {
                    width: parent.width
                    text: Media.artist || (Media.active ? "" : "Play something and it shows here")
                    color: Theme.muted
                }
            }
            WavyLine {
                width: parent.width
                visible: Media.length > 0
                value: root.played / Math.max(1, Media.length)
                phase: root.phase
                amplitude: Media.playing ? 3 : 0
                onSeeked: v => {
                    Media.seek(v);
                    root.played = v * Media.length;
                }
            }
            RowLayout {
                width: parent.width
                visible: Media.length > 0
                Txt {
                    text: Media.time(root.played)
                    font.pixelSize: Theme.small
                    color: Theme.muted
                }
                Item {
                    Layout.fillWidth: true
                }
                Txt {
                    text: Media.time(Media.length)
                    font.pixelSize: Theme.small
                    color: Theme.muted
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                bottomPadding: 4
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_previous"
                    size: 44
                    iconSize: 26
                    onClicked: Media.previous()
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Media.playing ? "pause" : "play_arrow"
                    size: 60
                    iconSize: 32
                    on: true
                    onClicked: Media.toggle()
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_next"
                    size: 44
                    iconSize: 26
                    onClicked: Media.next()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: root.shown === "notify" || root.shown === "claude"
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
