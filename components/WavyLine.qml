import QtQuick
import QtQuick.Shapes
import qs.config

// A Material wavy progress line: what's done as a wave (moving along while `moving`), the rest a straight soft
// track, a dot where it's at. Click or drag to seek: seeked(0 … 1).
Item {
    id: root
    property real value: 0
    property real phase: 0                        // the wave's drift (the caller moves it while playing)
    property real amplitude: 3
    property real wavelength: 26
    property real stroke: 4
    signal seeked(real v)
    implicitHeight: 24

    readonly property real at: Math.max(0, Math.min(1, value)) * width
    function wave() {
        const out = [], cy = height / 2;
        for (let x = 0; x <= at; x += 2)
            out.push(Qt.point(x, cy + amplitude * Math.sin((x / wavelength) * 2 * Math.PI - phase)));
        if (out.length < 2)
            out.push(Qt.point(at, cy));
        return out;
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {                               // the rest
            strokeColor: Theme.well
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: Math.min(root.width, root.at + 8)
            startY: root.height / 2
            PathLine {
                x: root.width
                y: root.height / 2
            }
        }
        ShapePath {                               // done
            strokeColor: Theme.ink
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathPolyline {
                path: root.width > 0 ? root.wave() : []
            }
        }
    }
    Rectangle {                                   // where it's at
        x: root.at - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: 16
        radius: 2
        color: Theme.ink
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onPressed: e => root.seeked(Math.max(0, Math.min(1, e.x / width)))
        onPositionChanged: e => {
            if (pressed)
                root.seeked(Math.max(0, Math.min(1, e.x / width)));
        }
    }
}
