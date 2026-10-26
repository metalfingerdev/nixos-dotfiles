import QtQuick

// A thick pill slider (Android's quick settings): the primary fill carries the icon, the value sits
// at the far end of the track. value: 0..1, bound to the real level; act in onMoved.
// Press or drag anywhere to set it: moved() fires on every move (live), and the slider shows the
// drag position meanwhile, so a slow source doesn't make it jump back.
// `iconClicked` (with iconClickable): a click on the icon itself, e.g. mute.
// Keyboard: Tab reaches it, Left/Right step it by `step`, Enter/Space click the icon.
Item {
    id: root

    property real value: 0
    property string icon: ""
    property string valueText: Math.round(shown * 100) + "%"
    property bool iconClickable: false
    property real step: 0.05
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool dragging: drag.pressed && !overIcon
    property real dragValue: 0
    readonly property real shown: clamp(dragging ? dragValue : value)

    signal moved(real value)
    // the value the user settled on: on release, and on every key or wheel step. For a setting that
    // shouldn't change mid-drag (the island's Size: it rescales the slider under the pointer)
    signal committed(real value)
    signal iconClicked()

    function clamp(v) { return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0 }

    activeFocusOnTab: true
    function nudge(by) { const v = clamp(value + by); moved(v); committed(v) }
    Keys.onLeftPressed:   nudge(-step)
    Keys.onRightPressed:  nudge(step)
    Keys.onReturnPressed: if (iconClickable) iconClicked()
    Keys.onSpacePressed:  if (iconClickable) iconClicked()

    implicitWidth: 300
    implicitHeight: 52
    opacity: enabled ? 1 : 0.38

    property bool overIcon: false

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Config.high

        // the fill never gets narrower than the icon's circle, so the icon always sits on it
        Rectangle {
            id: fill
            width: track.height + (track.width - track.height) * root.shown
            height: parent.height
            radius: height / 2
            color: Config.primary
            Behavior on width { enabled: !root.dragging; NumberAnimation { duration: 90 } }
        }

        Icon {
            id: glyph
            x: (track.height - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 22
            filled: true
            color: Config.primaryInk
        }

        FocusRing { on: root.keyboardSelected }

        // the value, at the far end: dim on the track, and the same text clipped to the fill on
        // top of it, so it reads wherever the fill's edge cuts through it
        Text {
            id: amount
            x: track.width - width - 16
            anchors.verticalCenter: parent.verticalCenter
            text: root.valueText
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
        }
        Item {
            width: fill.width
            height: parent.height
            clip: true

            Text {
                x: amount.x
                y: amount.y
                text: amount.text
                color: Config.primaryInk
                font: amount.font
            }
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function at(x) { return root.clamp((x - track.height / 2) / Math.max(1, width - track.height)) }
        onPressed: mouse => {
            root.overIcon = root.iconClickable && mouse.x < track.height
            if (root.overIcon) return
            root.dragValue = at(mouse.x)
            root.moved(root.dragValue)
        }
        onPositionChanged: mouse => {
            if (!pressed || root.overIcon) return
            const v = at(mouse.x)
            if (Math.abs(v - root.dragValue) >= 0.005) { root.dragValue = v; root.moved(v) }
        }
        onReleased: mouse => {
            if (root.overIcon && mouse.x < track.height) root.iconClicked()
            else if (!root.overIcon) root.committed(root.dragValue)
            root.overIcon = false
        }
        // the wheel nudges it
        onWheel: wheel => root.nudge(wheel.angleDelta.y > 0 ? root.step : -root.step)
    }
}
