import QtQuick
import qs.modules.components
import qs.modules.services

// The row moves with the island, as one motion: `finalWidth` is where the row is going, at once. The
// view sizes itself to it, so the island starts the same ease toward the same width in the same frame,
// and the row's ends and the island's edges stay together. `width` is where the row is now.
Item {
    id: root

    property real size: 46
    property real spacing: 8

    readonly property int count: Desktops.shown
    readonly property real wide: Math.round(size * 1.5)
    readonly property bool focusShown: Desktops.activeId >= 1 && Desktops.activeId <= count
    readonly property real finalWidth: count * size + Math.max(0, count - 1) * spacing + (focusShown ? wide - size : 0)

    // One entry per button there is: a ListModel, so adding or removing one leaves the others alone
    // (a number as the model rebuilds every button whenever it changes). Buttons on their way out
    // stay until they've shrunk away (trim), so there are never fewer than are shown.
    ListModel { id: slots }
    function grow() { while (slots.count < count) slots.append({ ws: slots.count + 1 }) }
    function trim() { while (slots.count > count && buttons.itemAt(slots.count - 1)?.gone) slots.remove(slots.count - 1) }
    onCountChanged: grow()

    // the buttons there at the start are simply there; only later ones grow in
    property bool ready: false
    Component.onCompleted: { grow(); ready = true }

    implicitWidth: row.implicitWidth
    implicitHeight: size

    Row {
        id: row

        Repeater {
            id: buttons
            model: slots

            // A slot is the button plus the gap before it, so a button that comes or goes takes its
            // gap with it. `span` (animated) is its width now; the button follows it: below its full
            // size it is scaled down (growing in, shrinking away), above it stretches (focused).
            Item {
                id: slot
                required property int index
                readonly property int wsId: index + 1
                readonly property bool present: index < root.count
                readonly property bool current: wsId === Desktops.activeId
                readonly property bool used: Desktops.occupied(wsId)
                readonly property real lead: index > 0 ? root.spacing : 0
                readonly property real goal: present ? lead + (current ? root.wide : root.size) : 0
                readonly property real full: lead + root.size
                readonly property real grown: Math.max(0, Math.min(1, span / full))
                readonly property bool gone: !present && !motion.running && Math.abs(span) < 0.5

                property real span: 0
                Behavior on span {
                    enabled: root.ready
                    Motion {
                        id: motion
                        onRunningChanged: if (!running) Qt.callLater(root.trim)
                    }
                }
                // set after completion, so a slot created later grows open from nothing
                Component.onCompleted: span = Qt.binding(() => slot.goal)

                width: span
                height: root.size

                Rectangle {
                    id: ws
                    readonly property bool ring: activeFocus && Config.focusVisible
                    function activate() { Desktops.focus(slot.wsId) }

                    x: slot.lead * slot.grown
                    width: Math.max(root.size, slot.span - slot.lead)
                    height: root.size
                    scale: slot.grown
                    transformOrigin: Item.Left
                    visible: slot.grown > 0
                    opacity: slot.grown

                    radius: height / 2
                    color: slot.current ? Config.state(Config.primary, Config.primaryInk, area.containsMouse, area.pressed || ring)
                         : slot.used ? Config.state(Config.high, Config.text, area.containsMouse, area.pressed || ring)
                         : Config.layer(area.containsMouse, area.pressed || ring)
                    Behavior on color { ColorAnimation { duration: 200 } }

                    // one on its way out can't be reached
                    enabled: slot.present
                    activeFocusOnTab: slot.present

                    Label {
                        anchors.centerIn: parent
                        text: slot.wsId
                        color: slot.current ? Config.primaryInk : slot.used ? Config.text : Config.dim
                        font.pixelSize: Config.body + 2
                        font.weight: slot.current || slot.used ? Font.DemiBold : Font.Normal
                    }

                    ClickArea {
                        id: area
                        onClicked: ws.activate()
                    }

                    FocusRing { on: ws.ring }
                }
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y !== 0) Desktops.stepWorkspace(event.angleDelta.y > 0 ? -1 : 1, 1, Desktops.shown)
        }
    }
}
