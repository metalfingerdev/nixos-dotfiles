import QtQuick

// A focusable card (Material 3): palettes, power actions. Lay its content out inside (children
// fill it, minus `padding`). `current` draws the primary ring (the palette in use); `tint`
// recolours it (a power action waiting for its confirming press).
// Mouse: click. Keyboard: Tab/arrows reach it, Enter/Space press it, like Pill.
Rectangle {
    id: root

    property bool current: false
    property color tint: "transparent"
    property int padding: 12
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    default property alias content: inner.data
    signal clicked()

    activeFocusOnTab: true
    function press() { clicked() }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    radius: Config.innerRadius + 4
    color: Config.state(tint.a > 0 ? tint : Config.container, Config.text, area.containsMouse, area.pressed || keyboardSelected)
    border.width: current || keyboardSelected ? 2 : 0
    border.color: Config.primary
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Item {
        id: inner
        anchors { fill: parent; margins: root.padding }
    }
}
