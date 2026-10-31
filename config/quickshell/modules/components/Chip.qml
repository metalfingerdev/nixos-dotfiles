import QtQuick

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

    readonly property color ink: selected ? Config.primaryInk : Config.dim

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36
    radius: height / 2
    color: selected ? Config.state(Config.primary, ink, area.containsMouse, area.pressed)
                    : Config.layer(area.containsMouse, area.pressed)
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
        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: root.ink
            font.weight: Font.Medium
        }
    }

    ClickArea {
        id: area
        onClicked: root.clicked()
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut; anchors.topMargin: -8 }
}
