import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.island.parts
import qs.modules.components
import qs.modules.services

// The glance: the peek view (hover the resting island) and `open expanded`. A dynamic indicator,
// not a menu:
//   the time and date; what's on, as one button group (only the things that are on), which opens
//   the dashboard
//   what's playing (the compact media card)
//   the newest notification, if any (opens the center)
//   a search bar: type (or click) to search apps, files and actions in the launcher
// A click anywhere else on the island opens the hub, Tabs (Bar.pinShown).
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""
    readonly property var newest: Notifier.items[0] ?? null

    implicitWidth: 440
    implicitHeight: column.implicitHeight + 32

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // whatever is typed goes to the launcher, which takes over from here
    function search(text) {
        Engine.query = text
        Engine.open(Engine.View.Launcher)
    }

    Column {
        id: column
        x: 16; y: 16
        width: parent.width - 32
        spacing: 12

        // ---- time, date, and what's on ----
        Item {
            width: parent.width
            height: Math.max(time.implicitHeight, statusGroup.implicitHeight)

            Column {
                id: time
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: -2

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.display - 4
                    font.weight: Font.Normal
                    font.features: { "tnum": 1 }
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
            }

            StatusGroup {
                id: statusGroup
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                maxText: 96
                maxWidth: parent.width - time.implicitWidth - 16
                onClicked: x => Engine.open(Engine.View.Dashboard, x)
            }
        }

        MediaCard {
            visible: root.media
            width: parent.width
            compact: true
        }

        // ---- the newest notification ----
        Rectangle {
            id: glance
            visible: root.newest !== null
            width: parent.width
            height: 48
            radius: height / 2
            color: Config.state(Config.container, Config.text, glanceArea.containsMouse, glanceArea.pressed)

            Rectangle {
                id: bell
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36; radius: 18
                color: Config.secondary

                Icon {
                    anchors.centerIn: parent
                    name: "notifications"
                    size: 18
                    filled: true
                    color: Config.secondaryInk
                }
            }
            Text {
                anchors { left: bell.right; leftMargin: 10; right: count.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: root.newest ? (root.newest.ref?.appName || "Notification") + "  ·  " + (root.newest.ref?.summary ?? "") : ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.body
            }
            Rectangle {
                id: count
                visible: Notifier.count > 1
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                width: Math.max(24, number.implicitWidth + 12)
                height: 24
                radius: 12
                color: Config.primary

                Text {
                    id: number
                    anchors.centerIn: parent
                    text: Notifier.count
                    color: Config.primaryInk
                    font.family: Config.font
                    font.pixelSize: Config.small
                    font.weight: Font.Bold
                }
            }
            MouseArea {
                id: glanceArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => Engine.open(Engine.View.Notifications, mapToItem(null, mouse.x, mouse.y).x)
            }
        }

        // ---- search: typing here starts the launcher ----
        Item {
            width: parent.width
            height: bar.implicitHeight

            SearchBar {
                id: bar
                anchors.fill: parent
                placeholder: "Search apps, files and actions"
                focus: true                       // hovering the glance and typing searches
                onKey: Engine.key()
                onAccepted: root.search(text)
                onEscaped: Engine.close()
                onTextChanged: if (text !== "") root.search(text)
            }
            // a click goes straight to the launcher (the field only matters for typing)
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.search("")
            }
        }
    }
}
