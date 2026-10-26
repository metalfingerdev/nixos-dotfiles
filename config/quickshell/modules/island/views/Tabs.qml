import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.island.parts
import qs.modules.components
import qs.modules.services

// The hub, opened by a click on the clock (Compact) or the glance (Expanded). One bar:
//   back         the view that was open before (Backspace too); Escape closes
//   workspaces   numbered, with the switcher's logic: up to the last one in use and one empty; the
//                focused one a wide primary pill, ones with windows filled, empty ones an outline.
//                Click to go there; the wheel steps through
//   tabs         one icon per view (and a screenshot), each opens it
//   status       what's on (the same group as the glance): opens the dashboard
//   clock        the time and date: opens the calendar
// Keys: arrows/Tab move between buttons, Enter presses, 1-9 switch workspace, each tab's letter
// opens it (shown as a keycap while the keyboard is in use), Escape goes back.
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property var tabs: [
        { icon: Config.symbol.dashboard,     key: "d", view: Engine.View.Dashboard },
        { icon: Config.symbol.calendar,      key: "c", view: Engine.View.Clock },
        { icon: Config.symbol.media,         key: "m", view: Engine.View.Media },
        { icon: Config.symbol.launcher,      key: "a", view: Engine.View.Launcher },
        { icon: Config.symbol.notifications, key: "n", view: Engine.View.Notifications },
        { icon: Config.symbol.overview,      key: "w", view: Engine.View.Workspaces },
        { icon: Config.symbol.screenshot,    key: "s", view: -1 },            // screenshot
        { icon: Config.symbol.theme,         key: "t", view: Engine.View.Theme },
        { icon: Config.symbol.power,         key: "p", view: Engine.View.Power }
    ]

    function activate(tab, x) {
        if (tab.view >= 0) { Engine.open(tab.view, x); return }
        Engine.close()                              // out of the way before the area is picked
        Toggles.screenshot()
    }

    implicitWidth: row.implicitWidth + 32
    implicitHeight: 80

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

    component Divider: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 36
        color: Config.divider
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 14

        // ---- back, then the workspaces: the switcher's logic, numbered ----
        BackButton {
            anchors.verticalCenter: parent.verticalCenter
            onClicked: Engine.back()
        }

        WorkspaceButtons {
            anchors.verticalCenter: parent.verticalCenter
            across: 0
            size: 46
            spacing: 6
        }

        Divider {}

        // ---- tabs ----
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Repeater {
                model: root.tabs

                Pill {
                    id: tab
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: 52
                    kind: "text"
                    icon: modelData.icon
                    iconSize: 26
                    shortcut: modelData.key
                    visible: modelData.view >= 0 || Toggles.has("grimblast")
                    onClicked: x => root.activate(modelData, x)

                    // unread notifications: a count on the bell
                    Rectangle {
                        visible: tab.modelData.view === Engine.View.Notifications && Notifier.count > 0
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
                    // playing: a dot under the note
                    Rectangle {
                        visible: tab.modelData.view === Engine.View.Media && Players.playing
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 2 }
                        width: 4; height: 4; radius: 2
                        color: Config.primary
                    }
                }
            }
        }

        Divider {}

        // ---- status ----
        StatusGroup {
            anchors.verticalCenter: parent.verticalCenter
            segmentHeight: 46
            maxText: 100
            onClicked: x => Engine.open(Engine.View.Dashboard, x)
        }

        Divider {}

        // ---- clock ----
        Rectangle {
            id: when
            readonly property bool ring: activeFocus && Config.focusVisible
            anchors.verticalCenter: parent.verticalCenter
            width: dateColumn.implicitWidth + 24
            height: 56
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
                    anchors.right: parent.right
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.title + 2
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
                Text {
                    anchors.right: parent.right
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
    }
}
