import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// Expanded's own top row sits at its ends (the same clock and the same group at the same height), so
// the island opens up between them.
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

    Keys.onPressed: event => {
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            Engine.key()
            Desktops.focus(event.key - Qt.Key_0)
            event.accepted = true
        } else event.accepted = false
    }

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

        Rectangle {
            id: when
            readonly property bool ring: activeFocus && Config.focusVisible
            anchors.verticalCenter: parent.verticalCenter
            width: dateColumn.implicitWidth + 16
            height: 52
            radius: Config.innerRadius
            color: Config.layer(whenArea.containsMouse, whenArea.pressed || ring)

            activeFocusOnTab: true
            function activate() { Engine.open(Engine.View.Clock) }

            DateStamp {
                id: dateColumn
                anchors.centerIn: parent
                date: clock.date
            }

            ClickArea {
                id: whenArea
                onClicked: mouse => Engine.open(Engine.View.Clock, whenArea.sceneX(mouse))
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

        Capsule {
            id: actions

            Tab { icon: Config.symbol.launcher; shortcut: "d"; view: Engine.View.Launcher; focus: true }
            Tab { icon: Config.symbol.mixer;    shortcut: "v"; view: Engine.View.Mixer }
            Tab { icon: Config.symbol.settings; shortcut: "i"; view: Engine.View.Settings }
            Tab { icon: Config.symbol.power;    shortcut: "x"; view: Engine.View.Power }
            Tab {
                icon: Config.symbol.notifications; shortcut: "n"; view: Engine.View.Notifications

                Rectangle {
                    visible: Notifier.count > 0
                    x: parent.width - width + 2
                    y: parent.height - height - 2           // the corner above is the keycap's
                    width: Math.max(16, unread.implicitWidth + 8)
                    height: 16
                    radius: 8
                    color: Config.primary

                    Label {
                        id: unread
                        anchors.centerIn: parent
                        text: Notifier.count > 99 ? "99+" : Notifier.count
                        color: Config.primaryInk
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }
        }

        StatusGroup {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            maxText: 100
            onClicked: (view, x) => Engine.open(view, x)
        }
    }
}
