import QtQuick

// Three gradients, and exact: an HSL colour is a straight line between those stops in each direction.
Item {
    id: root

    property real hue: 0
    property real lightness: 0.5
    property real saturation: 1
    property bool keyboardSelected: activeFocus && Config.focusVisible

    signal moved(real hue, real lightness)

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    activeFocusOnTab: true
    Keys.onLeftPressed:  moved(clamp(hue - 1 / 120), lightness)
    Keys.onRightPressed: moved(clamp(hue + 1 / 120), lightness)
    Keys.onUpPressed:    moved(hue, clamp(lightness + 0.02))
    Keys.onDownPressed:  moved(hue, clamp(lightness - 0.02))

    implicitWidth: 480
    implicitHeight: 240

    Rectangle {
        id: hues
        anchors.fill: parent
        radius: Config.innerRadius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;     color: "#ff0000" }
            GradientStop { position: 1 / 6; color: "#ffff00" }
            GradientStop { position: 2 / 6; color: "#00ff00" }
            GradientStop { position: 3 / 6; color: "#00ffff" }
            GradientStop { position: 4 / 6; color: "#0000ff" }
            GradientStop { position: 5 / 6; color: "#ff00ff" }
            GradientStop { position: 1;     color: "#ff0000" }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: hues.radius
        gradient: Gradient {
            GradientStop { position: 0;   color: Qt.rgba(1, 1, 1, 1) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1;   color: Qt.rgba(0, 0, 0, 1) }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: hues.radius
        opacity: 1 - root.saturation
        gradient: Gradient {
            GradientStop { position: 0; color: "#ffffff" }
            GradientStop { position: 1; color: "#000000" }
        }
    }

    Rectangle {
        x: root.hue * root.width - width / 2
        y: (1 - root.lightness) * root.height - height / 2
        width: 24
        height: 24
        radius: 12
        color: Qt.hsla(root.hue, root.saturation, root.lightness, 1)
        border.width: 3
        border.color: "#ffffff"

        // a dark hairline, so the white ring still has an edge on the map's white
        Rectangle {
            anchors { fill: parent; margins: -1 }
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#80000000"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        preventStealing: true

        function set(mouse) { root.moved(root.clamp(mouse.x / width), root.clamp(1 - mouse.y / height)) }
        onPressed: mouse => set(mouse)
        onPositionChanged: mouse => { if (pressed) set(mouse) }
    }

    FocusRing { target: hues; on: root.keyboardSelected }
}
