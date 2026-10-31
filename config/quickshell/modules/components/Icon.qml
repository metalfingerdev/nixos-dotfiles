import QtQuick

// By ligature name: https://fonts.google.com/icons
Text {
    property string name: ""
    property real size: 18
    property bool filled: false

    text: name
    color: Config.text
    font.family: Config.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0 })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
