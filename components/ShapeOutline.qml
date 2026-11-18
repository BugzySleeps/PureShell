import QtQuick
import QtQuick.Shapes
import qs.config
import "Shapes.js" as Shapes

// A widget's shape (Shapes.js: a cookie, a clover, a flower…), filled, morphing (a little springy) into a new
// one when `shape` changes. `angle` turns the outline (0 … 1 of a turn; it glides there), never what's inside:
// the content's box is worked out for the turned shape. `inner` is the box its content gets ([w, h, fits], 0 … 1 of its own): the biggest
// that fits in the shape with room for `need` px. A plain box isn't drawn here (the widget's own rounded
// rectangle is), and costs nothing. The outline is worked out off the main thread.
Item {
    id: root
    property string shape: "box"
    property color color: Theme.surface
    property color borderColor: "transparent"
    property real borderWidth: 0
    property var need: [0, 0]
    property real pad: 8
    property real angle: 0                       // 0 … 1 of a turn
    property real angleShown: angle
    Behavior on angleShown {
        SpringAnimation {
            spring: 4
            damping: 0.4
            epsilon: 0.001
        }
    }

    property var from: []
    property var to: []
    property real t: 1
    readonly property bool active: shape !== "box" || morph.running
    readonly property var now: from.length && t < 1 ? Shapes.mix(from, to, t) : to
    readonly property var inner: to.length && shape !== "box" ? Shapes.place(Shapes.turned(to, angle), width, height, need, need, pad) : [1, 1, true]

    function target() {
        return Shapes.rays(shape, width, height, Math.min(28, width / 2, height / 2));
    }
    property string was: shape
    onShapeChanged: {
        const before = was;
        was = shape;
        if (width <= 0)
            return;
        from = to.length ? now : Shapes.rays(before, width, height, Math.min(28, width / 2, height / 2));
        to = target();
        morph.restart();
    }
    onWidthChanged: refit()
    onHeightChanged: refit()
    Component.onCompleted: refit()
    function refit() {
        if (width <= 0 || height <= 0)
            return;
        if (!active) {                           // a box: nothing to work out
            to = [];
            from = [];
        } else if (!to.length || Shapes.free(shape)) {
            to = target();
            if (!morph.running)
                from = [];
        }
    }
    NumberAnimation {
        id: morph
        target: root
        property: "t"
        from: 0
        to: 1
        duration: 520
        easing.type: Easing.OutBack
        easing.overshoot: 1.3
        onFinished: root.refit()
    }

    Shape {
        anchors.fill: parent
        visible: root.now.length > 0
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true
        ShapePath {
            fillColor: root.color
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: root.now.length ? Shapes.points(root.now, root.width, root.height, root.angleShown, root.borderWidth / 2) : []
            }
        }
    }
}
