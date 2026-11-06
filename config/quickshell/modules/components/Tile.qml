import QtQuick

Rectangle {
    id: root

    property bool current: false
    property color tint: "transparent"
    property int padding: 14
    property string shortcut: ""
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    default property alias content: inner.data
    signal clicked()

    activeFocusOnTab: true
    function activate() { clicked() }

    radius: Config.cardRadius
    color: Config.state(tint.a > 0 ? tint : Config.container, Config.text, area.containsMouse, area.pressed || keyboardSelected)
    border.width: current ? 2 : 0
    border.color: Config.primary
    Behavior on color { ColorAnimation { duration: 120 } }

    ClickArea {
        id: area
        onClicked: root.clicked()
    }

    Item {
        id: inner
        anchors { fill: parent; margins: root.padding }
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut }
}
