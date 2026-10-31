import QtQuick

Rectangle {
    property string key: ""

    anchors { right: parent.right; top: parent.top; rightMargin: -6; topMargin: -6 }
    visible: key !== "" && Config.focusVisible
    width: Math.max(20, label.implicitWidth + 10)
    height: 20
    radius: 6
    color: Config.highest
    border.width: 1
    border.color: Config.outline
    z: 101

    Text {
        id: label
        anchors.centerIn: parent
        text: parent.key.length === 1 ? parent.key.toUpperCase() : parent.key
        color: Config.text
        font.family: Config.mono
        font.pixelSize: 11
        font.weight: Font.Bold
    }
}
