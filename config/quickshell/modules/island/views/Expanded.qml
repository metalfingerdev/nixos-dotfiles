import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The dashboard: the peek view (hover the resting island) and `open expanded`.
//   the time and date; Wi-Fi, Bluetooth and battery at a glance (each opens its view)
//   what's playing, with its controls (click the title for the full card)
//   one icon per view
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property var entries: [
        { icon: "wifi",               view: Engine.View.Network },
        { icon: "bluetooth",          view: Engine.View.Bluetooth },
        { icon: "music_note",         view: Engine.View.Media },
        { icon: "apps",               view: Engine.View.Launcher },
        { icon: "notifications",      view: Engine.View.Notifications },
        { icon: "grid_view",          view: Engine.View.Workspaces },
        { icon: "calendar_month",     view: Engine.View.Clock },
        { icon: "battery_full",       view: Engine.View.Battery },
        { icon: "palette",            view: Engine.View.Theme },
        { icon: "power_settings_new", view: Engine.View.Power }
    ]

    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""

    implicitWidth: Math.max(400, icons.implicitWidth + 24)
    implicitHeight: column.implicitHeight + 24

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // one line of status: icon + text, clickable and focusable like a Pill
    component Status: Rectangle {
        id: status
        property string icon: ""
        property string text: ""
        property color tint: Config.text
        signal clicked(real sceneX)

        activeFocusOnTab: true
        Keys.onReturnPressed: clicked(-1)
        Keys.onEnterPressed:  clicked(-1)
        Keys.onSpacePressed:  clicked(-1)

        implicitWidth: line.implicitWidth + 16
        implicitHeight: 24
        radius: height / 2
        color: activeFocus ? Config.selected : area.containsMouse ? Config.hover : "transparent"

        Row {
            id: line
            anchors.centerIn: parent
            spacing: 6
            Icon { name: status.icon; size: 15; color: status.tint; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 150)
                text: status.text
                elide: Text.ElideRight
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.small + 1
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => status.clicked(area.mapToItem(null, mouse.x, mouse.y).x)
        }
    }

    Column {
        id: column
        x: 12; y: 12
        width: parent.width - 24
        spacing: 10

        // ---- time and status ----
        Item {
            width: parent.width
            height: Math.max(clockColumn.implicitHeight, statusColumn.implicitHeight)

            Column {
                id: clockColumn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: 34
                    font.weight: Font.Light
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
            }

            Column {
                id: statusColumn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Status {
                    anchors.right: parent.right
                    icon: Net.current ? "wifi" : Net.ethernet ? "lan" : Net.wifiEnabled ? "wifi_find" : "wifi_off"
                    tint: Net.current || Net.ethernet ? Config.text : Config.faint
                    text: Net.summary
                    onClicked: x => Engine.open(Engine.View.Network, x)
                }
                Status {
                    readonly property var device: Bluez.connected[0] ?? null
                    anchors.right: parent.right
                    icon: device ? "bluetooth_connected" : Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
                    tint: device ? Config.accent : Bluez.enabled ? Config.text : Config.faint
                    text: device ? device.name + (device.batteryAvailable ? "  " + Math.round(device.battery * 100) + "%" : "")
                                 : Bluez.summary
                    onClicked: x => Engine.open(Engine.View.Bluetooth, x)
                }
                Status {
                    visible: Energy.present
                    anchors.right: parent.right
                    icon: Energy.charging ? "battery_charging_full" : Energy.level === "critical" ? "battery_alert" : "battery_full"
                    tint: Energy.charging || Energy.full ? Config.good : Energy.level === "ok" ? Config.text : Config.warn
                    text: Energy.percent + "%" + (Energy.minutesLeft >= 0 ? "  ·  " + Energy.duration(Energy.minutesLeft)
                                                                                 + (Energy.charging ? " to full" : " left") : "")
                    onClicked: x => Engine.open(Engine.View.Battery, x)
                }
            }
        }

        // ---- now playing ----
        Rectangle {
            visible: root.media
            width: parent.width
            height: 48
            radius: Config.innerRadius + 2
            color: Config.raised

            ClippingRectangle {
                id: art
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                radius: 6
                color: Config.hover

                Image {
                    id: cover
                    anchors.fill: parent
                    source: Players.active?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(68, 68)
                }
                Equalizer {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    running: Players.playing
                    barWidth: 2
                }
            }

            Column {
                anchors { left: art.right; leftMargin: 10; right: controls.left; rightMargin: 8; verticalCenter: parent.verticalCenter }

                Text {
                    width: parent.width
                    text: Players.active?.trackTitle ?? ""
                    elide: Text.ElideRight
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.body
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: Players.active?.trackArtist || Players.active?.identity || ""
                    elide: Text.ElideRight
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.small
                }
            }

            // the title opens the full card; the controls work in place
            MouseArea {
                anchors { left: parent.left; right: controls.left; top: parent.top; bottom: parent.bottom }
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => Engine.open(Engine.View.Media, mapToItem(null, mouse.x, mouse.y).x)
            }

            Row {
                id: controls
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 4

                Pill { icon: "skip_previous"; enabled: Players.active?.canGoPrevious ?? false; onClicked: Players.previous() }
                Pill { icon: Players.playing ? "pause" : "play_arrow"; enabled: Players.canToggle; onClicked: Players.toggle() }
                Pill { icon: "skip_next"; enabled: Players.active?.canGoNext ?? false; onClicked: Players.next() }
            }
        }

        // ---- every view ----
        Row {
            id: icons
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Repeater {
                model: root.entries

                Pill {
                    required property var modelData
                    icon: modelData.icon
                    onClicked: x => Engine.open(modelData.view, x)
                }
            }
        }
    }
}
