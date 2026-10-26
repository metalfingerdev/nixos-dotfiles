import QtQuick

// On/off switch (Material 3). It only reports: bind `checked` to the real state and act in onToggled.
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

    implicitWidth: 52
    implicitHeight: 32
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Config.primary : Config.high
        border.width: root.checked ? 0 : 2
        border.color: Config.outline
        Behavior on color { ColorAnimation { duration: 140 } }

        FocusRing { on: root.activeFocus }

        // the handle grows when on, and under the pointer
        Rectangle {
            readonly property real size: root.checked || area.pressed ? track.height - 8 : track.height - 14
            width: area.containsMouse && !root.checked ? size + 2 : size
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? track.width - width - 4 : (track.height - width) / 2
            color: root.checked ? Config.primaryInk : Config.outline
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 120 } }

            Icon {
                anchors.centerIn: parent
                visible: root.checked
                name: "check"
                size: 14
                color: Config.primary
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.flip()
    }
}
