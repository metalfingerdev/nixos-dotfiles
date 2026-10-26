import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.island.parts
import qs.modules.components
import qs.modules.services

// Everything, like Android's quick settings, in two columns so it fits a laptop screen:
//   left   the time, settings and power; Wi-Fi and Bluetooth (the circle switches, the rest opens
//          the list); a tile per quick setting this machine can do; volume and brightness;
//          the power profile (with power-profiles-daemon)
//   right  what's playing, then every notification (scrolls), with Clear all
// Opened from the glance's status group (Expanded), from Tabs, and by `open dashboard`.
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""
    readonly property int leftW: 420
    readonly property int rightW: 372

    implicitWidth: leftW + rightW + 16 + 40
    implicitHeight: quick.implicitHeight + 40

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- quick settings: a static list (so toggling one doesn't rebuild the grid); state is read live ----
    readonly property var tiles: [
        { key: "dnd",        icon: "do_not_disturb_on", title: "Do not disturb" },
        { key: "night",      icon: "nightlight",        title: "Night light",   tool: "hyprsunset" },
        { key: "caffeine",   icon: "coffee",            title: "Caffeine",      tool: "systemd-inhibit" },
        { key: "airplane",   icon: "flight",            title: "Airplane mode" },
        { key: "mic",        icon: "mic",               title: "Microphone" },
        { key: "dark",       icon: "dark_mode",         title: "Dark theme" },
        { key: "record",     icon: "screen_record",     title: "Screen record", tool: "wf-recorder" },
        { key: "screenshot", icon: "screenshot_region", title: "Screenshot",    tool: "grimblast" }
    ].filter(t => !t.tool || Toggles.has(t.tool))
    readonly property real tileW: (leftW - 8) / 2

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
        case "dark": {
            const dark = !Config.dark
            Config.name = dark ? Config.lastDark : "paper"
            Toggles.colorScheme(dark)
            break
        }
        case "record":
            if (!Toggles.recording) Engine.close()       // record the screen, not the dashboard
            Toggles.record(!Toggles.recording)
            break
        case "screenshot": Engine.close(); Toggles.screenshot(); break
        }
    }

    Component.onCompleted: Toggles.readProfile()

    // ================= left: quick settings =================
    Column {
        id: quick
        x: 20; y: 20
        width: root.leftW
        spacing: 12

        // ---- time, settings, power ----
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
                    font.pixelSize: Config.display - 4
                    font.features: { "tnum": 1 }
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8

                Pill { icon: "palette"; implicitHeight: 44; iconSize: 20; onClicked: x => Engine.open(Engine.View.Theme, x) }
                Pill { icon: "power_settings_new"; implicitHeight: 44; iconSize: 20; onClicked: x => Engine.open(Engine.View.Power, x) }
            }
        }

        // ---- tiles, two to a row like Android: Wi-Fi and Bluetooth first ----
        Grid {
            columns: 2
            spacing: 8

            QuickTile {
                width: root.tileW
                implicitHeight: 60
                focus: true                              // the keyboard starts here
                icon: Net.icon
                title: Net.ethernet && !Net.current ? "Ethernet" : "Wi-Fi"
                subtitle: Net.attempt ? "Connecting…" : Net.current ? Net.current.name
                        : Net.ethernet ? (Net.linkSpeed > 0 ? "Connected  ·  " + Net.linkSpeed + " Mb/s" : "Connected") : Net.summary
                on: Net.wifiEnabled || Net.ethernet
                split: true
                more: true
                enabled: Net.available
                onToggled: Net.setWifi(!Net.wifiEnabled)
                onClicked: x => Engine.open(Engine.View.Network, x)
            }
            QuickTile {
                width: root.tileW
                implicitHeight: 60
                icon: Bluez.connected.length > 0 ? "bluetooth_connected" : Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
                title: "Bluetooth"
                subtitle: Bluez.summary
                on: Bluez.enabled
                split: true
                more: true
                enabled: Bluez.available && !Bluez.blocked
                onToggled: Bluez.setEnabled(!Bluez.enabled)
                onClicked: x => Engine.open(Engine.View.Bluetooth, x)
            }

            Repeater {
                model: root.tiles

                QuickTile {
                    required property var modelData
                    width: root.tileW
                    implicitHeight: 60
                    icon: root.glyph(modelData.key, modelData.icon)
                    title: modelData.title
                    subtitle: root.status(modelData.key)
                    on: root.isOn(modelData.key)
                    onToggled: root.flip(modelData.key)
                }
            }
        }

        // ---- levels ----
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

        // ---- power profile ----
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

    // ================= right: media and notifications =================
    Column {
        id: side
        x: quick.x + quick.width + 16
        y: 20
        width: root.rightW
        height: quick.height
        spacing: 12

        MediaCard {
            id: mediaCard
            visible: root.media
            width: parent.width
        }

        Item {
            id: notifHeader
            width: parent.width
            height: 36

            Text {
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: "Notifications" + (Notifier.count > 0 ? "  " + Notifier.count : "")
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.large
                font.weight: Font.Medium
            }
            Pill {
                visible: Notifier.count > 0
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                kind: "text"
                text: "Clear all"
                onClicked: Notifier.dismissAll()
            }
        }

        ScrollList {
            id: notes
            visible: Notifier.count > 0
            width: parent.width
            maxHeight: side.height - notifHeader.height - side.spacing
                       - (mediaCard.visible ? mediaCard.height + side.spacing : 0)
            spacing: 8

            Repeater {
                model: ScriptModel { values: Notifier.items; objectProp: "id" }
                delegate: NotificationCard {
                    width: notes.width
                    center: true
                }
            }
        }

        // ---- nothing to show ----
        Column {
            visible: Notifier.count === 0
            width: parent.width
            topPadding: 24
            spacing: 8

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: Notifier.dnd ? "notifications_off" : "notifications_none"
                size: 36
                color: Config.outline
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifier.dnd ? "Do not disturb is on" : "No notifications"
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.body
            }
        }
    }
}
