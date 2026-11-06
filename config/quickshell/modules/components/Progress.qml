import QtQuick

// NaN/Infinity from a flaky source shows as 0.
// seek() fires once, on release, so a player isn't spammed.
// The fill is deliberately not animated: a 250 ms position poll would keep restarting it.
Item {
    id: root

    property real fraction: 0
    property color color: Config.primary
    property bool seekable: false
    property int thickness: 4
    property real step: 0.02

    readonly property bool hovered: area.containsMouse
    readonly property bool dragging: area.pressed && seekable
    property real dragFraction: 0
    readonly property real shownFraction: clamp(dragging ? dragFraction : fraction)

    signal seek(real fraction)

    function clamp(v) { return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0 }

    activeFocusOnTab: seekable
    function nudge(dir) { seek(clamp(fraction + dir * step)) }

    implicitWidth: 200
    implicitHeight: seekable ? 20 : thickness

    Rectangle {
        id: track
        width: parent.width
        height: root.seekable && (root.hovered || root.dragging || root.activeFocus) ? root.thickness * 1.5 : root.thickness
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: Config.high
        Behavior on height { NumberAnimation { duration: 100 } }

        Rectangle {
            width: track.width * root.shownFraction
            height: parent.height
            radius: parent.radius
            color: root.color
        }

        FocusRing { on: root.activeFocus }
    }

    Rectangle {
        visible: root.seekable && (root.hovered || root.dragging || (root.activeFocus && Config.focusVisible))
        width: root.thickness * 2.5
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: track.width * root.shownFraction - width / 2
        color: root.color
    }

    ClickArea {
        id: area
        visible: root.seekable

        function at(x) { return root.clamp(x / width) }
        onPressed: mouse => root.dragFraction = at(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.dragFraction = at(mouse.x) }
        onReleased: root.seek(root.dragFraction)
    }
}
