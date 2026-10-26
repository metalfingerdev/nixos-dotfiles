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
            color: "#f7f7f7"
            font.pixelSize: 13
        }

        Rectangle {
            id: track
            width: 130; height: 6; radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: "#2a2a2a"

            Rectangle {
                width: track.width * Math.max(0, Math.min(1, root.fraction))
                height: parent.height
                radius: parent.radius
                color: "#f7f7f7"
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        Text {
            width: 36
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.valueText
            color: "#f7f7f7"
            font.pixelSize: 13
        }
    }
}