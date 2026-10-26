import QtQuick

// The keys a view answers to that have no button to badge (volume up, seek...), as keycaps and
// labels along its foot. Shown while the keyboard is in use (Config.focusVisible).
//   KeyHints { keys: [["+ −", "volume"], ["[ ]", "brightness"]] }
Flow {
    id: root

    property var keys: []

    visible: Config.focusVisible && keys.length > 0
    spacing: 16

    Repeater {
        model: root.keys

        Row {
            required property var modelData
            spacing: 6

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(22, cap.implicitWidth + 12)
                height: 22
                radius: 6
                color: Config.high
                border.width: 1
                border.color: Config.outline

                Text {
                    id: cap
                    anchors.centerIn: parent
                    text: modelData[0]
                    color: Config.text
                    font.family: Config.mono
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData[1]
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.small
            }
        }
    }
}
