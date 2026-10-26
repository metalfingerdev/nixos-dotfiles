import QtQuick

// A filter chip (Material 3): outlined when off, the primary fill when selected. Click, Enter/Space
// when focused, or its `shortcut` key report clicked(); bind `selected` to the real state.
Rectangle {
    id: root

    property alias text: label.text
    property string icon: ""
    property bool selected: false
    property string shortcut: ""
    property bool keyboardSelected: activeFocus && Config.focusVisible
    signal clicked()

    activeFocusOnTab: true
    function activate() { clicked() }
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed:  clicked()
    Keys.onSpacePressed:  clicked()

    readonly property color ink: selected ? Config.primaryInk : Config.dim

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36
    radius: height / 2
    color: selected ? Config.state(Config.primary, ink, area.containsMouse, area.pressed)
                    : Qt.rgba(Config.text.r, Config.text.g, Config.text.b, area.pressed ? 0.12 : area.containsMouse ? 0.08 : 0)
    border.width: selected ? 0 : 1
    border.color: Config.outline
    Behavior on color { ColorAnimation { duration: 140 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 18
            color: root.ink
        }
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: root.ink
            font.family: Config.font
            font.pixelSize: Config.body
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut; anchors { right: parent.right; top: parent.top; rightMargin: -6; topMargin: -8 } }
}
