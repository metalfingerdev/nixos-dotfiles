import QtQuick
import QtQuick.Window
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

Item {
    id: root

    readonly property int pad: 20
    readonly property int contentW: 600
    readonly property int gap: 10
    readonly property real third: (contentW - 2 * gap) / 3
    readonly property int tileH: 62
    readonly property int tileRadius: 24

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Functions, not values: the list itself stays put when a setting flips, so the tile with the
    // keyboard focus isn't rebuilt under it. `opens` makes it an Android large tile.
    readonly property var tiles: [
        { letter: "b", title: "Bluetooth", opens: Engine.View.Bluetooth, usable: () => Bluez.available && !Bluez.blocked,
          isOn: () => Bluez.enabled, icon: () => Bluez.icon, status: () => Bluez.summary,
          flip: () => Bluez.setEnabled(!Bluez.enabled) },
        { letter: "d", title: "Do not disturb", opens: Engine.View.Notifications,
          isOn: () => Notifier.dnd, icon: () => Notifier.dnd ? Config.symbol.dnd : "do_not_disturb_off",
          status: () => Notifier.dnd ? "On" : Notifier.count > 0 ? Notifier.count + " notifications" : "Off",
          flip: () => Notifier.dnd = !Notifier.dnd },
        { letter: "l", title: "Night light", tool: "hyprsunset",
          isOn: () => Toggles.nightLight, icon: () => "nightlight", status: () => Toggles.nightLight ? Toggles.warmth + " K" : "Off",
          flip: () => Toggles.nightLight = !Toggles.nightLight },
        { letter: "c", title: "Caffeine", tool: "systemd-inhibit",
          isOn: () => Toggles.caffeine, icon: () => "coffee", flip: () => Toggles.caffeine = !Toggles.caffeine },
        { letter: "a", title: "Airplane mode",
          isOn: () => Toggles.airplane, icon: () => "flight", flip: () => Toggles.setAirplane(!Toggles.airplane) },
        { letter: "m", title: "Microphone",
          isOn: () => Audio.hasMic && !Audio.micMuted, icon: () => Audio.hasMic && !Audio.micMuted ? "mic" : "mic_off",
          status: () => !Audio.hasMic ? "No microphone" : Audio.micMuted ? "Muted" : "On", flip: () => Audio.toggleMic() },
        { letter: "k", title: "Dark theme",
          isOn: () => Config.dark, icon: () => "dark_mode", flip: () => { Config.setDark(!Config.dark); Toggles.colorScheme(Config.dark) } },
        { letter: "r", title: "Screen record", tool: "wf-recorder",
          isOn: () => Toggles.recording, icon: () => Config.symbol.record, status: () => Toggles.recording ? Toggles.recordTime : "Off",
          // record the screen, not the dashboard
          flip: () => { if (!Toggles.recording) Engine.close(); Toggles.record(!Toggles.recording) } },
        { letter: "s", title: "Screenshot", tool: "grimblast",
          isOn: () => false, icon: () => Config.symbol.screenshot, status: () => "Select an area",
          flip: () => { Engine.close(); Toggles.screenshot() } }
    ].filter(t => !t.tool || Toggles.has(t.tool))

    Component.onCompleted: Toggles.readProfile()

    // levels from anywhere in the view (the tiles' letters are their shortcuts)
    Keys.onPressed: event => {
        const t = event.text
        if (t === "+" || t === "=") Audio.setVolume(Audio.volume + 5)
        else if (t === "-") Audio.setVolume(Audio.volume - 5)
        else if (t === "]") Backlight.set(Backlight.percent + 5)
        else if (t === "[") Backlight.set(Backlight.percent - 5)
        else { event.accepted = false; return }
        Engine.key()
    }

    // what the notification list may take: the screen, less the island's gap and everything else
    readonly property real othersH: [header, firstRow, grid, levels, profile, mediaCard, divider, notifHead, hints]
        .filter(i => i.visible).reduce((sum, i) => sum + i.height + column.spacing, 0)
    readonly property real roomForNotes: Math.max(150, (Screen.height || 1080) / Config.scale - 2 * pad - 24 - othersH)

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 14

        Header {
            id: header
            width: parent.width
            title: "Control Center"
            subtitle: Qt.formatDateTime(clock.date, "dddd, d MMMM  ·  HH:mm")
            onBack: Engine.back()

            Pill { kind: "text"; icon: Config.symbol.settings; iconSize: 22; shortcut: "i"; onClicked: Engine.open(Engine.View.Settings) }
            Pill { kind: "text"; icon: Config.symbol.power; iconSize: 22; shortcut: "p"; onClicked: Engine.open(Engine.View.Power) }
        }

        Row {
            id: firstRow
            spacing: root.gap

            QuickTile {
                width: root.third
                implicitHeight: root.tileH
                radius: root.tileRadius
                focus: true                              // the keyboard starts here
                icon: Net.icon
                title: Net.ethernet && !Net.current ? "Ethernet" : "Wi-Fi"
                subtitle: Net.attempt ? "Connecting…" : Net.current ? Net.current.name
                        : Net.ethernet ? "Connected" : Net.summary
                on: Net.wifiEnabled || Net.ethernet
                split: true
                shortcut: "w"
                enabled: Net.available
                onToggled: Net.setWifi(!Net.wifiEnabled)
                onClicked: x => Engine.open(Engine.View.Network, x)
            }
            QuickTile {
                width: 2 * root.third + root.gap
                implicitHeight: root.tileH
                radius: root.tileRadius
                icon: Audio.muted ? Config.symbol.muted : Config.symbol.sound
                title: "Audio"
                subtitle: Audio.muted ? "Muted  ·  " + Audio.label(Audio.sink) : Audio.label(Audio.sink)
                on: !Audio.muted
                split: true
                shortcut: "o"
                enabled: Audio.sink !== null
                onToggled: Audio.toggleMute()
                onClicked: x => Engine.open(Engine.View.Media, x)
            }
        }

        Grid {
            id: grid
            columns: 3
            spacing: root.gap

            Repeater {
                model: root.tiles

                QuickTile {
                    required property var modelData
                    width: root.third
                    implicitHeight: root.tileH
                    radius: root.tileRadius
                    icon: modelData.icon()
                    title: modelData.title
                    on: modelData.isOn()
                    subtitle: modelData.status?.() ?? (on ? "On" : "Off")
                    split: modelData.opens !== undefined
                    shortcut: modelData.letter
                    enabled: modelData.usable?.() ?? true
                    onToggled: modelData.flip()
                    onClicked: x => Engine.open(modelData.opens, x)
                }
            }
        }

        Column {
            id: levels
            width: parent.width
            spacing: root.gap

            VolumeSlider {
                width: parent.width
                implicitHeight: 48
                enabled: Audio.sink !== null
            }
            BrightnessSlider {
                visible: Backlight.available
                width: parent.width
                implicitHeight: 48
            }
        }

        Segmented {
            id: profile
            visible: Toggles.profile !== ""
            width: parent.width
            options: Toggles.profiles
            current: Toggles.profile
            onPicked: key => Toggles.setProfile(key)
        }

        MediaCard {
            id: mediaCard
            visible: Players.hasTrack
            width: parent.width
        }

        Rectangle {
            id: divider
            width: parent.width
            height: 1
            color: Config.divider
        }

        Item {
            id: notifHead
            width: parent.width
            height: 36

            Label {
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: "Notifications"
                color: Config.dim
                font.weight: Font.Medium
            }
            Pill {
                visible: Notifier.count > 0
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                implicitHeight: 36
                kind: "text"
                text: "Clear all"
                shortcut: "x"
                onClicked: Notifier.dismissAll()
            }
        }

        ScrollList {
            id: notes
            visible: Notifier.count > 0
            width: parent.width
            maxHeight: root.roomForNotes
            spacing: 8

            Repeater {
                model: ScriptModel { values: Notifier.items; objectProp: "id" }
                delegate: NotificationCard {
                    width: notes.innerWidth
                    center: true
                }
            }
        }

        Label {
            visible: Notifier.count === 0
            width: parent.width
            topPadding: 4
            bottomPadding: 4
            horizontalAlignment: Text.AlignHCenter
            text: Notifier.dnd ? "Do not disturb is on" : "No notifications"
            color: Config.dim
        }

        KeyHints {
            id: hints
            width: parent.width
            keys: [["Space", "switch"], ["Enter", "open"], ["+ −", "volume"], ["[ ]", "brightness"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
