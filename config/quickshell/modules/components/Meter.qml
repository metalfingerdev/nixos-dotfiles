import QtQuick

// Dumb bar: label + track + value. Views feed it.
Item {
    id: root
    property string label: ""
    property real fraction: 0          // 0..1
    property string valueText: ""

    implicitWidth: 260
    implicitHeight: 44

    Row {
        anchors.centerIn: parent
        spacing: 12

        Text {
            width: 36
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.body
        }

        Rectangle {
            id: track
            width: 130; height: 6; radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: Config.track

            Rectangle {
                width: track.width * Math.max(0, Math.min(1, root.fraction))
                height: parent.height
                radius: parent.radius
                color: Config.text
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        Text {
            width: 36
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.valueText
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.body
        }
    }
}