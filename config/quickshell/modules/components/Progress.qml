import QtQuick

// A level bar (media position, battery). fraction: 0..1; NaN/Infinity from a flaky source shows as 0.
// With `seekable`, click or drag to seek: while dragging it shows the drag position, and seek()
// fires once, on release, so a player isn't spammed. It grows and shows a knob under the pointer.
// The fill is deliberately not animated: a 250 ms position poll would keep restarting it.
Item {
    id: root

    property real fraction: 0
    property color color: Config.text
    property bool seekable: false
    property int thickness: 4

    readonly property bool hovered: area.containsMouse
    readonly property bool dragging: area.pressed && seekable
    property real dragFraction: 0
    readonly property real shownFraction: clamp(dragging ? dragFraction : fraction)

    signal seek(real fraction)

    function clamp(v) { return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0 }

    implicitWidth: 200
    implicitHeight: seekable ? 16 : thickness           // a tall hit area, a thin track

    Rectangle {
        id: track
        width: parent.width
        height: root.seekable && (root.hovered || root.dragging) ? root.thickness * 1.5 : root.thickness
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: Config.track
        Behavior on height { NumberAnimation { duration: 100 } }

        Rectangle {
            width: track.width * root.shownFraction
            height: parent.height
            radius: parent.radius
            color: root.color
        }
    }

    Rectangle {
        visible: root.seekable && (root.hovered || root.dragging)
        width: root.thickness * 2.5
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: track.width * root.shownFraction - width / 2
        color: root.color
    }

    MouseArea {
        id: area
        anchors.fill: parent
        visible: root.seekable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function at(x) { return root.clamp(x / width) }
        onPressed: mouse => root.dragFraction = at(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.dragFraction = at(mouse.x) }
        onReleased: root.seek(root.dragFraction)
    }
}
