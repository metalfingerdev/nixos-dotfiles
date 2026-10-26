import QtQuick

// Shared button. Mouse: click. Keyboard: Tab/arrows reach it (Bar's default keys), Enter/Space press it.
// `icon` (a Material Symbols name) goes before the text; with no text it is a round icon button.
Rectangle {
    id: root

    property alias text: label.text
    property string icon: ""
    // highlighted for keyboard navigation. Default: it has focus. A view that keeps focus elsewhere
    // (the launcher's search field) binds it to its own selection instead.
    property bool keyboardSelected: activeFocus
    // the "on" look (accent text), e.g. a running scan or the current player
    property bool active: false
    // sceneX: where the mouse clicked. -1 from the keyboard: there's no pointer to anchor to, so a
    // view opened with it (Engine.open(v, x)) is centred, the same as one opened over IPC.
    signal clicked(real sceneX)

    activeFocusOnTab: true
    function press() { clicked(-1) }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    implicitWidth: label.text === "" && icon !== "" ? implicitHeight : content.implicitWidth + 24
    implicitHeight: 28
    radius: height / 2
    color: keyboardSelected ? Theme.selected : area.containsMouse ? Theme.hover : Theme.raised
    border.width: keyboardSelected ? 1 : 0
    border.color: Theme.faint
    opacity: enabled ? 1 : 0.4

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 17
            filled: root.active
            color: root.active ? Theme.accent : Theme.text
        }

        Text {
            id: label
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            color: root.active ? Theme.accent : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.body
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouse => root.clicked(area.mapToItem(null, mouse.x, mouse.y).x)
    }
}
