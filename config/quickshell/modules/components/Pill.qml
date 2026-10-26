import QtQuick

// Shared button. Mouse: click. Keyboard: Tab/arrows reach it (Bar's default keys), Enter/Space press it.
Rectangle {
    id: root

    property alias text: label.text
    // highlighted for keyboard navigation. Default: it has focus. A view that keeps focus elsewhere
    // (the launcher's search field) binds it to its own selection instead.
    property bool keyboardSelected: activeFocus
    // sceneX: where the mouse clicked. -1 from the keyboard: there's no pointer to anchor to, so a
    // view opened with it (Engine.open(v, x)) is centred, the same as one opened over IPC.
    signal clicked(real sceneX)

    activeFocusOnTab: true
    function press() { clicked(-1) }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: height / 2
    color: keyboardSelected ? "#3a3a3f" : area.containsMouse ? "#2e2e2e" : "#1a1a1a"
    border.width: keyboardSelected ? 1 : 0
    border.color: "#6a6a72"

    Text {
        id: label
        anchors.centerIn: parent
        color: "#f7f7f7"
        font.pixelSize: 13
    }
    
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouse => root.clicked(area.mapToItem(null, mouse.x, mouse.y).x)
    }
}