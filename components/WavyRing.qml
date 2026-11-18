import QtQuick
import QtQuick.Shapes
import qs.config

// A Material wavy progress ring: a soft track, and the part that's done as a fine, gentle wave round the circle,
// starting at the top. It eases to a new value, then stays still (the outline's worked out off the main thread).
Item {
    id: root
    property real value: 0                        // 0 … 1
    property real stroke: 3.5
    property int waves: 16
    property real amplitude: 1
    property color color: Theme.ink
    implicitWidth: 64
    implicitHeight: 64

    property real shown: value
    Behavior on shown {
        NumberAnimation {
            duration: Theme.slow
            easing.type: Easing.OutCubic
        }
    }
    function points(upTo, wavy) {
        const cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - stroke / 2 - amplitude - 1;
        const n = Math.max(2, Math.round(180 * upTo)), out = [];
        for (let i = 0; i <= n; i++) {
            const a = -Math.PI / 2 + (i / n) * upTo * 2 * Math.PI;
            const rr = r + (wavy ? amplitude * Math.sin((a + Math.PI / 2) * waves) : 0);
            out.push(Qt.point(cx + rr * Math.cos(a), cy + rr * Math.sin(a)));
        }
        return out;
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true
        ShapePath {                               // the track
            strokeColor: Theme.well
            strokeWidth: root.stroke
            fillColor: "transparent"
            PathPolyline {
                path: root.width > 0 ? root.points(1, false) : []
            }
        }
        ShapePath {                               // done
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: root.width > 0 && root.shown > 0.005 ? root.points(Math.min(1, root.shown), true) : []
            }
        }
    }
}
