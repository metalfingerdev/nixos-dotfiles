import QtQuick

// Material's focus indicator: a thick ring just outside the focused control, in the primary colour,
// so it reads against the surface whatever the control's own fill is. Shown only while the keyboard
// is in use (Config.focusVisible). Put one inside a focusable control; it follows its corners:
//   FocusRing {}                         (target: the parent)
//   FocusRing { target: track; on: root.activeFocus }
// gap < 0 draws it inside instead (segments of a group, which touch their neighbours).
Rectangle {
    id: ring

    property var target: parent          // any Item; its radius, if it has one, is followed
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
