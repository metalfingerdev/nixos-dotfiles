import QtQuick
import qs.modules.components
import qs.modules.services

// Numbered workspace buttons with the switcher's logic (WorkspaceDots), numbers instead of dots:
// every workspace up to the last one in use, then one empty one after it (Desktops.shown). The
// focused one takes the primary colour, and in a row it stretches like GNOME's bar; ones with
// windows are filled; empty ones are only an outline and a dim number.
// Click, or Enter/Space when focused, goes there; the wheel steps through them.
//   across: 0   one row (Tabs)        across: n   a grid of circles n wide (the glance)
Grid {
    id: root

    property int across: 0
    property real size: 46

    columns: across > 0 ? across : Math.max(1, Desktops.shown)
    spacing: 8

    Repeater {
        model: Desktops.shown

        Rectangle {
            id: ws
            required property int index
            readonly property int wsId: index + 1
            readonly property bool current: wsId === Desktops.activeId
            readonly property bool used: Desktops.occupied(wsId)
            readonly property bool ring: activeFocus && Config.focusVisible
            function activate() { Desktops.focus(wsId) }

            width: current && root.across === 0 ? Math.round(root.size * 1.5) : root.size
            height: root.size
            radius: height / 2
            color: current ? Config.state(Config.primary, Config.primaryInk, area.containsMouse, area.pressed || ring)
                 : used ? Config.state(Config.container, Config.text, area.containsMouse, area.pressed || ring)
                 : Qt.rgba(Config.text.r, Config.text.g, Config.text.b, area.pressed || ring ? 0.12 : area.containsMouse ? 0.08 : 0)
            border.width: current || used ? 0 : 1.5
            border.color: Config.outline
            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }

            activeFocusOnTab: true
            Keys.onReturnPressed: activate()
            Keys.onEnterPressed:  activate()
            Keys.onSpacePressed:  activate()

            Text {
                anchors.centerIn: parent
                text: ws.wsId
                color: ws.current ? Config.primaryInk : ws.used ? Config.text : Config.dim
                font.family: Config.font
                font.pixelSize: Config.body + 2
                font.weight: ws.current || ws.used ? Font.DemiBold : Font.Normal
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.activate()
            }

            FocusRing { on: ws.ring }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y !== 0) Desktops.stepWorkspace(event.angleDelta.y > 0 ? -1 : 1, 1, Desktops.shown)
        }
    }
}
