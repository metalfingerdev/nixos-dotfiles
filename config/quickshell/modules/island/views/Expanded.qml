import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.island.parts
import qs.modules.components
import qs.modules.services

// The glance: the peek view (hover the resting island) and `open expanded`. Where you come in.
//   left    the workspaces as numbered circles (the switcher's logic), then round buttons: the
//           dashboard, notifications, the overview, theme, screenshot, power
//   centre  a big clock (opens the calendar), the date, the battery
//   right   Wi-Fi, Bluetooth, Do not disturb, Sound: a click switches it, the round arrow inside
//           opens its own view
//   bottom  a strip with the search bar (type, or click, to search in the launcher), the Tabs button
//           (Tab), and what's playing
// A click anywhere else on the island opens Tabs too (Bar.pinShown).
// Keys: type to search, Tab opens Tabs, arrows leave the field for the buttons, Space switches a
// setting, Enter opens its view, Escape closes.
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""
    readonly property int pad: 24
    readonly property int circle: 58
    readonly property int sideW: 3 * circle + 2 * 12          // the left grid; the right tiles match it
    readonly property int tileW: 252

    implicitWidth: 920
    implicitHeight: column.implicitHeight + 2 * pad

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // whatever is typed goes to the launcher, which takes over from here
    function search(text) {
        Engine.query = text
        Engine.open(Engine.View.Launcher)
    }

    readonly property var actions: [
        { icon: Config.symbol.dashboard,     view: Engine.View.Dashboard },
        { icon: Config.symbol.notifications, view: Engine.View.Notifications },
        { icon: Config.symbol.overview,      view: Engine.View.Workspaces },
        { icon: Config.symbol.theme,         view: Engine.View.Theme },
        { icon: Config.symbol.screenshot,    view: -1 },
        { icon: Config.symbol.power,         view: Engine.View.Power }
    ].filter(a => a.view >= 0 || Toggles.has("grimblast"))

    function act(a, x) {
        if (a.view >= 0) { Engine.open(a.view, x); return }
        Engine.close()                                  // out of the way before the area is picked
        Toggles.screenshot()
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 22

        Item {
            width: parent.width
            height: Math.max(leftSide.implicitHeight, centre.implicitHeight, rightSide.implicitHeight)

            // ================= left: workspaces and the rest, round =================
            Column {
                id: leftSide
                anchors.verticalCenter: parent.verticalCenter
                width: root.sideW
                spacing: 16

                Grid {
                    columns: 3
                    spacing: 12

                    Repeater {
                        model: root.actions

                        Pill {
                            id: action
                            required property var modelData
                            implicitHeight: root.circle
                            icon: modelData.icon
                            iconSize: 26
                            onClicked: x => root.act(modelData, x)

                            // unread notifications: a count on the bell
                            Rectangle {
                                visible: action.modelData.view === Engine.View.Notifications && Notifier.count > 0
                                x: parent.width - width + 2
                                y: parent.height - height + 2
                                width: Math.max(20, unread.implicitWidth + 10)
                                height: 20
                                radius: 10
                                color: Config.primary

                                Text {
                                    id: unread
                                    anchors.centerIn: parent
                                    text: Notifier.count > 99 ? "99+" : Notifier.count
                                    color: Config.primaryInk
                                    font.family: Config.font
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }
                }
            }

            // ================= centre: the clock =================
            Column {
                id: centre
                anchors.centerIn: parent
                spacing: 6

                // the clock is a button: it opens the calendar
                Rectangle {
                    id: face
                    readonly property bool ring: activeFocus && Config.focusVisible
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: time.implicitWidth + 32
                    height: time.implicitHeight
                    radius: Config.cardRadius
                    color: Qt.rgba(Config.text.r, Config.text.g, Config.text.b, faceArea.pressed || ring ? 0.10 : faceArea.containsMouse ? 0.06 : 0)

                    activeFocusOnTab: true
                    Keys.onReturnPressed: Engine.open(Engine.View.Clock)
                    Keys.onEnterPressed:  Engine.open(Engine.View.Clock)
                    Keys.onSpacePressed:  Engine.open(Engine.View.Clock)

                    Text {
                        id: time
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 104
                        font.weight: Font.Light
                        font.features: { "tnum": 1 }
                    }
                    MouseArea {
                        id: faceArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => Engine.open(Engine.View.Clock, mapToItem(null, mouse.x, mouse.y).x)
                    }
                    FocusRing { on: face.ring }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.title
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 4
                    spacing: 8

                    Pill {
                        visible: Toggles.recording
                        implicitHeight: 40
                        icon: "radio_button_checked"
                        text: Toggles.recordTime
                        activeFocusOnTab: false
                        onClicked: Toggles.record(false)
                    }
                    Pill {
                        visible: Energy.present
                        implicitHeight: 40
                        kind: "text"
                        icon: Energy.glyph
                        text: Energy.percent + "%" + (Energy.charging ? "  ·  charging" : Energy.minutesLeft >= 0 ? "  ·  " + Energy.duration(Energy.minutesLeft) : "")
                        activeFocusOnTab: false
                        onClicked: x => Engine.open(Engine.View.Battery, x)
                    }
                }
            }

            // ================= right: the settings =================
            Column {
                id: rightSide
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: root.tileW
                spacing: 10

                QuickTile {
                    width: parent.width
                    implicitHeight: 56
                    icon: Net.icon
                    title: Net.ethernet && !Net.current ? "Ethernet" : "Wi-Fi"
                    subtitle: Net.current ? Net.current.name : Net.ethernet ? "Connected" : Net.wifiEnabled ? "On" : "Off"
                    on: Net.wifiEnabled || Net.ethernet
                    more: true
                    enabled: Net.available
                    onToggled: Net.setWifi(!Net.wifiEnabled)
                    onClicked: x => Engine.open(Engine.View.Network, x)
                }
                QuickTile {
                    width: parent.width
                    implicitHeight: 56
                    icon: Bluez.connected.length > 0 ? "bluetooth_connected" : Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
                    title: "Bluetooth"
                    subtitle: Bluez.summary
                    on: Bluez.enabled
                    more: true
                    enabled: Bluez.available && !Bluez.blocked
                    onToggled: Bluez.setEnabled(!Bluez.enabled)
                    onClicked: x => Engine.open(Engine.View.Bluetooth, x)
                }
                QuickTile {
                    width: parent.width
                    implicitHeight: 56
                    icon: Notifier.dnd ? Config.symbol.dnd : "do_not_disturb_off"
                    title: "Do not disturb"
                    subtitle: Notifier.dnd ? "On" : Notifier.count > 0 ? Notifier.count + " notifications" : "Off"
                    on: Notifier.dnd
                    more: true
                    onToggled: Notifier.dnd = !Notifier.dnd
                    onClicked: x => Engine.open(Engine.View.Notifications, x)
                }
                QuickTile {
                    width: parent.width
                    implicitHeight: 56
                    icon: Audio.muted ? Config.symbol.muted : Config.symbol.sound
                    title: "Sound"
                    subtitle: Audio.muted ? "Muted" : Audio.volume + "%  ·  " + Audio.label(Audio.sink)
                    on: !Audio.muted
                    more: true
                    enabled: Audio.sink !== null
                    onToggled: Audio.toggleMute()
                    onClicked: x => Engine.open(Engine.View.Media, x)
                }
            }
        }

        // ================= bottom: search, Tabs, what's playing =================
        Row {
            width: parent.width
            spacing: 12

            Item {
                width: parent.width - (player.visible ? player.width + parent.spacing : 0)
                height: bar.implicitHeight

                SearchBar {
                    id: bar
                    anchors.fill: parent
                    placeholder: "Search apps, files and actions"
                    focus: true                       // hovering the glance and typing searches
                    takesTab: true
                    onKey: Engine.key()
                    onAccepted: root.search(text)
                    onTab: Engine.open(Engine.View.Tabs)
                    onEscaped: Engine.close()
                    onTextChanged: if (text !== "") root.search(text)

                    // the way to every view: always labelled with its key
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: tabsRow.implicitWidth + 28
                        height: 44
                        radius: 22
                        color: Qt.rgba(Config.text.r, Config.text.g, Config.text.b, tabsArea.pressed ? 0.14 : tabsArea.containsMouse ? 0.08 : 0)

                        Row {
                            id: tabsRow
                            anchors.centerIn: parent
                            spacing: 8

                            Icon { anchors.verticalCenter: parent.verticalCenter; name: Config.symbol.hub; size: 20; color: Config.text }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Tabs"
                                color: Config.text
                                font.family: Config.font
                                font.pixelSize: Config.body
                                font.weight: Font.Medium
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: tabKey.implicitWidth + 12
                                height: 22
                                radius: 6
                                color: Config.highest
                                border.width: 1
                                border.color: Config.outline

                                Text {
                                    id: tabKey
                                    anchors.centerIn: parent
                                    text: "Tab"
                                    color: Config.text
                                    font.family: Config.mono
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }
                        }
                        MouseArea {
                            id: tabsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => Engine.open(Engine.View.Tabs, mapToItem(null, mouse.x, mouse.y).x)
                        }
                    }
                }
                // a click on the field goes straight to the launcher (the field only matters for typing)
                MouseArea {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: parent.right; rightMargin: 150 }
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.search("")
                }
            }

            // what's playing, small
            Rectangle {
                id: player
                visible: root.media
                width: 340
                height: bar.implicitHeight
                radius: height / 2
                color: Config.container

                ClippingRectangle {
                    id: art
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: 20
                    color: Config.high
                    Image {
                        anchors.fill: parent
                        source: Players.active?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(80, 80)
                    }
                }
                Column {
                    anchors { left: art.right; leftMargin: 10; right: playButton.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
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
                MouseArea {
                    anchors { left: parent.left; right: playButton.left; top: parent.top; bottom: parent.bottom }
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => Engine.open(Engine.View.Media, mapToItem(null, mouse.x, mouse.y).x)
                }
                Pill {
                    id: playButton
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    kind: "filled"
                    icon: Players.playing ? "pause" : "play_arrow"
                    iconSize: 24
                    enabled: Players.canToggle
                    onClicked: Players.toggle()
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Tab", "all tabs"], ["↑", "to the buttons"], ["Space", "on / off"], ["Enter", "open"], ["Esc", "close"]]
        }
    }
}
