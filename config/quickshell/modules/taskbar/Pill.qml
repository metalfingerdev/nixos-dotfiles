import QtQuick

// Tiny shared button so views can prove clicks inside the island work.
Rectangle {
    id: root

    property alias text: label.text
    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: height / 2
    color: area.containsMouse ? "#2e2e2e" : "#1a1a1a"

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
        onClicked: root.clicked()
    }
}