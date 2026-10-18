import QtQuick

// Seekable progress bar. Dumb like Meter: the view feeds `fraction` and reacts to `seeked`.
// Click or drag to seek; while dragging it shows the drag position instead of `fraction`,
// and only emits `seeked` on release so the player isn't spammed.
Item {
    id: root

    property real fraction: 0            // 0..1, fed by the view
    property bool seekable: true
    property int thickness: 4            // resting track height; grows 1.5x on hover/drag
    property color trackColor: "#2a2a2a"
    property color fillColor: "#f7f7f7"

    readonly property bool hovered: area.containsMouse
    readonly property bool dragging: area.pressed && seekable
    readonly property real shownFraction: clamp(dragging ? dragFraction : fraction)
    property real dragFraction: 0

    signal seeked(real fraction)

    implicitWidth: 200
    implicitHeight: 16                   // tall hit area, thin visual track

    // NaN/Infinity from a flaky player becomes 0 instead of poisoning the bindings
    function clamp(v) { return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0 }

    Rectangle {
        id: track
        width: parent.width
        height: (root.seekable && (root.hovered || root.dragging)) ? root.thickness * 1.5 : root.thickness
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: root.trackColor

        Behavior on height { NumberAnimation { duration: 100 } }

        // No Behavior on width: animating from NaN stays NaN, and the 250ms poll keeps restarting it.
        Rectangle {
            width: track.width * root.shownFraction
            height: parent.height
            radius: parent.radius
            color: root.fillColor
        }
    }

    // playhead knob, only when it can be grabbed
    Rectangle {
        width: root.thickness * 2.5
        height: width
        radius: width / 2
        color: root.fillColor
        anchors.verticalCenter: parent.verticalCenter
        x: track.width * root.shownFraction - width / 2
        visible: root.seekable && (root.hovered || root.dragging)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor

        // Deliberately never `enabled: false`: a disabled area lets the click fall through
        // to whatever closes the island.
        function fractionAt(x) { return root.clamp(x / width) }

        onPressed: (mouse) => { if (root.seekable) root.dragFraction = fractionAt(mouse.x) }
        onPositionChanged: (mouse) => { if (pressed && root.seekable) root.dragFraction = fractionAt(mouse.x) }
        onReleased: if (root.seekable) root.seeked(root.dragFraction)
    }
}