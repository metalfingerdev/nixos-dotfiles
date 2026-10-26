import QtQuick

// A Material Symbols glyph, by its ligature name: Icon { name: "wifi" }.
// Names: https://fonts.google.com/icons (the font comes from modules/features/theme.nix).
Text {
    property string name: ""
    property real size: 18
    property bool filled: false

    text: name
    color: Theme.text
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0 })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
