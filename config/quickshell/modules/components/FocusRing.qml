import QtQuick

// In the primary colour, so it reads against the surface whatever the control's own fill is.
Rectangle {
    id: ring

    property var target: parent
    property bool on: target ? target.activeFocus : false
    property real gap: 3
    readonly property real out: gap + border.width

    x: -out
    y: -out
    width: (target ? target.width : 0) + 2 * out
    height: (target ? target.height : 0) + 2 * out
    radius: Math.max(0, (target && target.radius !== undefined ? target.radius : 0) + out)
    visible: on && Config.focusVisible
    color: "transparent"
    border.width: 3
    border.color: Config.primary
    z: 100
}
