import QtQuick

// A focusable card: workspaces, palettes, power actions. Lay its content out inside (children
// fill it, minus `padding`). `current` draws the accent ring (the focused workspace, the palette
// in use); `tint` recolours it (a power action waiting for its confirming press).
// Mouse: click. Keyboard: Tab/arrows reach it, Enter/Space press it, like Pill.
Rectangle {
    id: root

    property bool current: false
    property color tint: "transparent"
    property int padding: 8
    property bool keyboardSelected: activeFocus
    readonly property bool hovered: area.containsMouse
    default property alias content: inner.data
    signal clicked()

    activeFocusOnTab: true
    function press() { clicked() }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    radius: Config.innerRadius + 2
    color: tint.a > 0 ? tint
         : keyboardSelected ? Config.selected : area.containsMouse ? Config.hover : Config.raised
    border.width: current ? 2 : keyboardSelected ? 1 : 0
    border.color: current ? Config.accent : Config.faint
    Behavior on color { ColorAnimation { duration: 100 } }

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
