import QtQuick
import QtQuick.Window
import Quickshell
import qs.modules.island
import qs.modules.island.parts
import qs.modules.components
import qs.modules.services

// The Control Center, one column like Android's quick settings:
//   back, the title, the date and time; theme and power
//   Wi-Fi beside a wide Audio tile, then Bluetooth, Do not disturb, Night light, then the rest,
//   three to a row. Tiles with a view of their own are Android's large tiles: the icon circle
//   switches them, the rest opens their view (Wi-Fi: networks, Audio: outputs and players,
//   Bluetooth: devices, Do not disturb: notifications)
//   volume and brightness, the power profile (with power-profiles-daemon), what's playing
//   notifications, with Clear all: the list takes whatever height the screen has left
// Keys: arrows/Tab move, Space switches a tile, Enter opens its view, each tile's letter switches
// it from anywhere, + − volume, [ ] brightness, Backspace back, Escape closes.
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""
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

    // ---- the tiles after the first row: a static list (so switching one doesn't rebuild the grid) ----
    readonly property var tiles: [
        { key: "bluetooth",  letter: "b", title: "Bluetooth",   split: true },
        { key: "dnd",        letter: "d", title: "Do not disturb", split: true },
        { key: "night",      letter: "l", title: "Night light",   tool: "hyprsunset" },
        { key: "caffeine",   letter: "c", title: "Caffeine",      tool: "systemd-inhibit" },
        { key: "airplane",   letter: "a", title: "Airplane mode" },
        { key: "mic",        letter: "m", title: "Microphone" },
        { key: "dark",       letter: "k", title: "Dark theme" },
        { key: "record",     letter: "r", title: "Screen record", tool: "wf-recorder" },
        { key: "screenshot", letter: "s", title: "Screenshot",    tool: "grimblast" }
    ].filter(t => !t.tool || Toggles.has(t.tool))

    function isOn(key) {
        switch (key) {
        case "bluetooth": return Bluez.enabled
        case "dnd":       return Notifier.dnd
        case "night":     return Toggles.nightLight
        case "caffeine":  return Toggles.caffeine
        case "airplane":  return Toggles.airplane
        case "mic":       return Audio.hasMic && !Audio.micMuted
        case "dark":      return Config.dark
        case "record":    return Toggles.recording
        }
        return false
    }
    function status(key) {
        switch (key) {
        case "bluetooth":  return Bluez.summary
        case "dnd":        return Notifier.dnd ? "On" : Notifier.count > 0 ? Notifier.count + " notifications" : "Off"
        case "mic":        return !Audio.hasMic ? "No microphone" : Audio.micMuted ? "Muted" : "On"
        case "record":     return Toggles.recording ? Toggles.recordTime : "Off"
        case "screenshot": return "Select an area"
        case "night":      return Toggles.nightLight ? Toggles.warmth + " K" : "Off"
        }
        return isOn(key) ? "On" : "Off"
    }
    function glyph(key) {
        switch (key) {
        case "bluetooth":  return Bluez.connected.length > 0 ? "bluetooth_connected" : Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
        case "dnd":        return isOn(key) ? Config.symbol.dnd : "do_not_disturb_off"
        case "night":      return "nightlight"
        case "caffeine":   return "coffee"
        case "airplane":   return "flight"
        case "mic":        return isOn(key) ? "mic" : "mic_off"
        case "dark":       return "dark_mode"
        case "record":     return Config.symbol.record
        case "screenshot": return Config.symbol.screenshot
        }
        return ""
    }
    function flip(key) {
        switch (key) {
        case "bluetooth":  Bluez.setEnabled(!Bluez.enabled); break
        case "dnd":        Notifier.dnd = !Notifier.dnd; break
        case "night":      Toggles.nightLight = !Toggles.nightLight; break
        case "caffeine":   Toggles.caffeine = !Toggles.caffeine; break
        case "airplane":   Toggles.setAirplane(!Toggles.airplane); break
        case "mic":        Audio.toggleMic(); break
        case "dark":       Config.setDark(!Config.dark); Toggles.colorScheme(Config.dark); break
        case "record":
            if (!Toggles.recording) Engine.close()       // record the screen, not the dashboard
            Toggles.record(!Toggles.recording)
            break
        case "screenshot": Engine.close(); Toggles.screenshot(); break
        }
    }
    // the view a split tile's body opens
    function details(key, x) {
        if (key === "bluetooth") Engine.open(Engine.View.Bluetooth, x)
        else if (key === "dnd") Engine.open(Engine.View.Notifications, x)
    }

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

            Pill { kind: "text"; icon: Config.symbol.theme; iconSize: 22; shortcut: "t"; onClicked: x => Engine.open(Engine.View.Theme, x) }
            Pill { kind: "text"; icon: Config.symbol.power; iconSize: 22; shortcut: "p"; onClicked: x => Engine.open(Engine.View.Power, x) }
        }

        // ---- Wi-Fi, and Audio twice as wide ----
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

        // ---- the rest, three to a row ----
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
                    icon: root.glyph(modelData.key)
                    title: modelData.title
                    subtitle: root.status(modelData.key)
                    on: root.isOn(modelData.key)
                    split: modelData.split ?? false
                    shortcut: modelData.letter
                    enabled: modelData.key !== "bluetooth" || (Bluez.available && !Bluez.blocked)
                    onToggled: root.flip(modelData.key)
                    onClicked: x => root.details(modelData.key, x)
                }
            }
        }

        // ---- levels ----
        Column {
            id: levels
            width: parent.width
            spacing: root.gap

            Slider {
                width: parent.width
                implicitHeight: 48
                icon: Audio.muted ? Config.symbol.muted : Audio.volume < 34 ? "volume_mute" : Audio.volume < 67 ? "volume_down" : Config.symbol.sound
                value: Audio.muted ? 0 : Audio.volume / 100
                valueText: Audio.muted ? "Muted" : Audio.volume + "%"
                iconClickable: true
                enabled: Audio.sink !== null
                onMoved: v => Audio.setVolume(v * 100)
                onIconClicked: Audio.toggleMute()
            }
            Slider {
                visible: Backlight.available
                width: parent.width
                implicitHeight: 48
                icon: Backlight.percent < 34 ? "brightness_low" : Backlight.percent < 67 ? "brightness_medium" : "brightness_high"
                value: Backlight.percent / 100
                onMoved: v => Backlight.set(v * 100)
            }
        }

        Segmented {
            id: profile
            visible: Toggles.profile !== ""
            width: parent.width
            options: [
                { key: "power-saver", label: "Saver",       icon: "eco" },
                { key: "balanced",    label: "Balanced",    icon: "balance" },
                { key: "performance", label: "Performance", icon: "speed" }
            ]
            current: Toggles.profile
            onPicked: key => Toggles.setProfile(key)
        }

        MediaCard {
            id: mediaCard
            visible: root.media
            width: parent.width
        }

        // ---- notifications ----
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

            Text {
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: "Notifications"
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.body
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

        Text {
            visible: Notifier.count === 0
            width: parent.width
            topPadding: 4
            bottomPadding: 4
            horizontalAlignment: Text.AlignHCenter
            text: Notifier.dnd ? "Do not disturb is on" : "No notifications"
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        KeyHints {
            id: hints
            width: parent.width
            keys: [["Space", "switch"], ["Enter", "open"], ["+ −", "volume"], ["[ ]", "brightness"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
