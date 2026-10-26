import QtQuick

// A control's shortcut key as a small keycap on its corner, shown while the keyboard is in use
// (Config.focusVisible). Controls with a `shortcut` place one themselves; ViewLoader presses the
// control when its key is typed.
Rectangle {
    property string key: ""

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
