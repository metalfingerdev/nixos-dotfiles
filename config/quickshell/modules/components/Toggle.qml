import QtQuick

// On/off switch. It only reports: bind `checked` to the real state and act in onToggled.
// Mouse: click. Keyboard: Tab/arrows reach it (ViewLoader's default keys), Enter/Space flip it.
// `enabled: false` greys it out and ignores input (e.g. Wi-Fi blocked by a hardware switch).
Item {
    id: root

    property bool checked: false
    signal toggled(bool on)

    function flip() { if (enabled) toggled(!checked) }

    activeFocusOnTab: true
    Keys.onReturnPressed: flip()
    Keys.onEnterPressed:  flip()
    Keys.onSpacePressed:  flip()

    implicitWidth: 38
    implicitHeight: 22
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Config.accent : Config.track
        border.width: root.activeFocus ? 1 : 0
        border.color: Config.text
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            width: parent.height - 6
            height: width
            radius: width / 2
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Config.surface : Config.dim
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.flip()
    }
}
