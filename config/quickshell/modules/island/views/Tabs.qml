import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// The hub: a click on the clock (Compact) or on Expanded opens it. One strip, with Expanded's own top
// row at its ends (the same clock and the same group at the same height), so the island opens up
// between them. Capsules of buttons side by side, after Apple's toolbars: no dividers, one size of
// button. Left to right:
//   clock          the time and date: opens the calendar
//   back           only with somewhere to go back to (Backspace too); Escape closes
//   spaces         the workspaces, numbered, with the switcher's logic: up to the last one in use and
//                  one empty; the focused one a wide primary pill, ones with windows filled, empty ones
//                  only their number. Click to go there; the wheel steps through. One coming or going
//                  moves the whole strip and the island's edges together (see implicitWidth). Then
//                  the overview
//   actions        one icon per view, each opens it; the bell has the unread count on it
//   status         what's on, one button each: the network, Bluetooth, Do not disturb and the battery
//                  open their own views; a recording, or the group around them, the dashboard
// Keys: arrows/Tab move between buttons, starting on search; Enter presses, 1-9 switch workspace, each
// button's letter opens it (shown as a keycap while the keyboard is in use).
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property int margin: 12
    readonly property int control: 40               // a button's height, as in StatusGroup
    readonly property int pad: 4                    // a capsule around its buttons, as in StatusGroup
    // Taken once: opening a view from here adds to the history while this one is still fading out,
    // and the island mustn't resize for that.
    property bool hasBack: Engine.snapshot.history.length > 0
    Component.onCompleted: hasBack = hasBack

    // Sized to where the workspace buttons are going (finalWidth), not to where they are: they
    // ease there on the island's own motion, so the strip (centred) and the island's edges move
    // as one.
    implicitWidth: 2 * margin + when.width + (hasBack ? back.width + row.spacing : 0)
                 + (workspaces.finalWidth + spaces.spacing + control + 2 * pad) + row.spacing
                 + actions.width + row.spacing + status.implicitWidth + row.spacing
    implicitHeight: 76                              // Expanded's top row and its padding

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // digits pick a workspace; the rest goes on to ViewLoader's defaults
    Keys.onPressed: event => {
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            Engine.key()
            Desktops.focus(event.key - Qt.Key_0)
            event.accepted = true
        } else event.accepted = false
    }

    // buttons on a capsule, like StatusGroup's
    component Capsule: Rectangle {
        default property alias buttons: inner.data
        property alias spacing: inner.spacing

        anchors.verticalCenter: parent.verticalCenter
        width: inner.implicitWidth + 2 * root.pad
        height: root.control + 2 * root.pad
        radius: height / 2
        color: Config.container

        Row {
            id: inner
            x: root.pad
            y: root.pad
            spacing: 2
        }
    }

    // a round icon button that opens `view`
    component Tab: Pill {
        required property int view
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: root.control
        kind: "text"
        onClicked: x => Engine.open(view, x)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        // ---- clock: its text where Expanded's is ----
        Rectangle {
            id: when
            readonly property bool ring: activeFocus && Config.focusVisible
            anchors.verticalCenter: parent.verticalCenter
            width: dateColumn.implicitWidth + 16
            height: 52
            radius: Config.innerRadius
            color: Qt.rgba(Config.text.r, Config.text.g, Config.text.b, whenArea.pressed || ring ? 0.12 : whenArea.containsMouse ? 0.08 : 0)

            activeFocusOnTab: true
            Keys.onReturnPressed: Engine.open(Engine.View.Clock)
            Keys.onEnterPressed:  Engine.open(Engine.View.Clock)
            Keys.onSpacePressed:  Engine.open(Engine.View.Clock)

            Column {
                id: dateColumn
                anchors.centerIn: parent
                spacing: -1

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.title + 2
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "ddd d MMM")
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.small
                }
            }

            MouseArea {
                id: whenArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => Engine.open(Engine.View.Clock, mapToItem(null, mouse.x, mouse.y).x)
            }

            FocusRing { on: when.ring }
        }

        BackButton {
            id: back
            visible: root.hasBack
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: root.control + 2 * root.pad
            onClicked: Engine.back()
        }

        // ---- the workspaces and the overview ----
        Capsule {
            id: spaces
            spacing: 4

            WorkspaceButtons {
                id: workspaces
                anchors.verticalCenter: parent.verticalCenter
                size: root.control
                spacing: 4
            }
            Tab { icon: Config.symbol.overview; shortcut: "w"; view: Engine.View.Workspaces }
        }

        // ---- the other views ----
        Capsule {
            id: actions

            Tab { icon: Config.symbol.launcher; shortcut: "d"; view: Engine.View.Launcher; focus: true }
            Tab { icon: Config.symbol.mixer;    shortcut: "v"; view: Engine.View.Mixer }
            Tab { icon: Config.symbol.settings; shortcut: "i"; view: Engine.View.Settings }
            Tab { icon: Config.symbol.power;    shortcut: "x"; view: Engine.View.Power }
            Tab {
                icon: Config.symbol.notifications; shortcut: "n"; view: Engine.View.Notifications

                // unread notifications: a count on the bell
                Rectangle {
                    visible: Notifier.count > 0
                    x: parent.width - width + 2
                    y: parent.height - height - 2           // the corner above is the keycap's
                    width: Math.max(16, unread.implicitWidth + 8)
                    height: 16
                    radius: 8
                    color: Config.primary

                    Text {
                        id: unread
                        anchors.centerIn: parent
                        text: Notifier.count > 99 ? "99+" : Notifier.count
                        color: Config.primaryInk
                        font.family: Config.font
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // ---- status: at the far end, as in Expanded ----
        StatusGroup {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            maxText: 100
            onClicked: (view, x) => Engine.open(view, x)
        }
    }
}
