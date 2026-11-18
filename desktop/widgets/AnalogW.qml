import QtQuick
import Quickshell
import qs.config
import qs.components

// A round face: twelve dots, rounded ink hands, a thin second hand.
Item {
    id: root
    readonly property real s: Math.min(width, height)
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    Item {
        anchors.centerIn: parent
        width: root.s
        height: root.s
        Repeater {
            model: 12
            Rectangle {
                required property int index
                readonly property real a: index * 30 * Math.PI / 180
                readonly property real r: root.s / 2 - 6
                width: index % 3 === 0 ? 6 : 4
                height: width
                radius: width / 2
                color: index % 3 === 0 ? Theme.ink : Theme.line
                x: root.s / 2 + r * Math.sin(a) - width / 2
                y: root.s / 2 - r * Math.cos(a) - height / 2
            }
        }
        // a hand: from the middle, `len` of the way out, turned `deg`
        component Hand: Rectangle {
            property real len: 0.3
            property real deg: 0
            width: 6
            height: root.s * len
            radius: width / 2
            x: root.s / 2 - width / 2
            y: root.s / 2 - height + width / 2
            transformOrigin: Item.Bottom
            rotation: deg
            antialiasing: true
        }
        Hand {
            len: 0.26
            width: 7
            color: Theme.ink
            deg: (clock.date.getHours() % 12) * 30 + clock.date.getMinutes() / 2
        }
        Hand {
            len: 0.36
            width: 5
            color: Theme.inkSoft
            deg: clock.date.getMinutes() * 6
        }
        Hand {
            len: 0.4
            width: 2
            color: Theme.muted
            deg: clock.date.getSeconds() * 6
        }
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 10
            radius: 5
            color: Theme.ink
        }
    }
}
