import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.island.parts
import qs.modules.components
import qs.modules.services

// Quick settings, like Android's, laid out wide for a laptop:
//   top     the time and date; notifications (a count; opens the center), theme, power
//   left    the tiles, two to a row: Wi-Fi and Bluetooth (the circle switches, the rest opens the
//           list), then every quick setting this machine can do
//   right   what's playing, volume and brightness, the power profile (with power-profiles-daemon)
// Keys: arrows/Tab move, Space flips a tile, Enter opens its list, each tile's letter flips it
// from anywhere, + − volume, [ ] brightness, Escape/Backspace back.
// Opened from the glance's status group (Expanded), from Tabs, and by `open dashboard`.
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""
    readonly property int pad: 24
    readonly property int leftW: 480
    readonly property int rightW: 420
    readonly property int gutter: 20
    readonly property real tileW: (leftW - 12) / 2

    implicitWidth: leftW + gutter + rightW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- quick settings: a static list (so toggling one doesn't rebuild the grid); state is read live ----
    readonly property var tiles: [
        { key: "dnd",        letter: "d", icon: "do_not_disturb_on", title: "Do not disturb" },
        { key: "night",      letter: "l", icon: "nightlight",        title: "Night light",   tool: "hyprsunset" },
        { key: "caffeine",   letter: "c", icon: "coffee",            title: "Caffeine",      tool: "systemd-inhibit" },
        { key: "airplane",   letter: "a", icon: "flight",            title: "Airplane mode" },
        { key: "mic",        letter: "m", icon: "mic",               title: "Microphone" },
        { key: "dark",       letter: "k", icon: "dark_mode",         title: "Dark theme" },
        { key: "record",     letter: "r", icon: "screen_record",     title: "Screen record", tool: "wf-recorder" },
        { key: "screenshot", letter: "s", icon: "screenshot_region", title: "Screenshot",    tool: "grimblast" }
    ].filter(t => !t.tool || Toggles.has(t.tool))

    function isOn(key) {
        switch (key) {
        case "dnd":      return Notifier.dnd
        case "night":    return Toggles.nightLight
        case "caffeine": return Toggles.caffeine
        case "airplane": return Toggles.airplane
        case "mic":      return Audio.hasMic && !Audio.micMuted
        case "dark":     return Config.dark
        case "record":   return Toggles.recording
        }
        return false
    }
    function status(key) {
        switch (key) {
        case "mic":        return !Audio.hasMic ? "No microphone" : Audio.micMuted ? "Muted" : "On"
        case "record":     return Toggles.recording ? Toggles.recordTime : "Off"
        case "screenshot": return "Select an area"
        case "night":      return Toggles.nightLight ? Toggles.warmth + " K" : "Off"
        }
        return isOn(key) ? "On" : "Off"
    }
    function glyph(key, icon) {
        if (key === "mic" && !isOn(key)) return "mic_off"
        if (key === "dnd" && !isOn(key)) return "do_not_disturb_off"
        return icon
    }
    function flip(key) {
        switch (key) {
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

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 20

        // ---- time, and the way to everything else ----
        Item {
            width: parent.width
            height: time.implicitHeight

            Column {
                id: time
                anchors.left: parent.left
                spacing: -2

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.display
                    font.features: { "tnum": 1 }
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.large
                }
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 10

                Pill {
                    id: bell
                    icon: Notifier.dnd ? "notifications_off" : "notifications"
                    text: Notifier.count > 0 ? String(Notifier.count) : ""
                    implicitHeight: 52
                    iconSize: 24
                    shortcut: "n"
                    onClicked: x => Engine.open(Engine.View.Notifications, x)
                }
                Pill { icon: "palette"; implicitHeight: 52; iconSize: 24; shortcut: "t"; onClicked: x => Engine.open(Engine.View.Theme, x) }
                Pill { icon: "power_settings_new"; implicitHeight: 52; iconSize: 24; shortcut: "p"; onClicked: x => Engine.open(Engine.View.Power, x) }
            }
        }

        Row {
            spacing: root.gutter

            // ================= left: the tiles =================
            Grid {
                id: grid
                width: root.leftW
                columns: 2
                spacing: 12

                QuickTile {
                    width: root.tileW
                    focus: true                              // the keyboard starts here
                    icon: Net.icon
                    title: Net.ethernet && !Net.current ? "Ethernet" : "Wi-Fi"
                    subtitle: Net.attempt ? "Connecting…" : Net.current ? Net.current.name
                            : Net.ethernet ? (Net.linkSpeed > 0 ? "Connected  ·  " + Net.linkSpeed + " Mb/s" : "Connected") : Net.summary
                    on: Net.wifiEnabled || Net.ethernet
                    split: true
                    more: true
                    shortcut: "w"
                    enabled: Net.available
                    onToggled: Net.setWifi(!Net.wifiEnabled)
                    onClicked: x => Engine.open(Engine.View.Network, x)
                }
                QuickTile {
                    width: root.tileW
                    icon: Bluez.connected.length > 0 ? "bluetooth_connected" : Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
                    title: "Bluetooth"
                    subtitle: Bluez.summary
                    on: Bluez.enabled
                    split: true
                    more: true
                    shortcut: "b"
                    enabled: Bluez.available && !Bluez.blocked
                    onToggled: Bluez.setEnabled(!Bluez.enabled)
                    onClicked: x => Engine.open(Engine.View.Bluetooth, x)
                }

                Repeater {
                    model: root.tiles

                    QuickTile {
                        required property var modelData
                        width: root.tileW
                        icon: root.glyph(modelData.key, modelData.icon)
                        title: modelData.title
                        subtitle: root.status(modelData.key)
                        on: root.isOn(modelData.key)
                        shortcut: modelData.letter
                        onToggled: root.flip(modelData.key)
                    }
                }
            }

            // ================= right: media and levels =================
            Column {
                width: root.rightW
                spacing: 14

                MediaCard {
                    visible: root.media
                    width: parent.width
                }
                // nothing playing: a quiet card, so the column keeps its shape
                Rectangle {
                    visible: !root.media
                    width: parent.width
                    height: 164
                    radius: Config.cardRadius
                    color: Config.container

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "music_off"; size: 32; color: Config.outline }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Nothing is playing"
                            color: Config.dim
                            font.family: Config.font
                            font.pixelSize: Config.body
                        }
                    }
                }

                Slider {
                    width: parent.width
                    icon: Audio.muted ? "volume_off" : Audio.volume < 34 ? "volume_mute" : Audio.volume < 67 ? "volume_down" : "volume_up"
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
                    icon: Backlight.percent < 34 ? "brightness_low" : Backlight.percent < 67 ? "brightness_medium" : "brightness_high"
                    value: Backlight.percent / 100
                    onMoved: v => Backlight.set(v * 100)
                }

                Segmented {
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
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Space", "flip"], ["Enter", "open"], ["+ −", "volume"], ["[ ]", "brightness"], ["Esc", "back"]]
        }
    }
}
