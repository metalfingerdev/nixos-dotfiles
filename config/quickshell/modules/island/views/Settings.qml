import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.lock
import qs.modules.services

// The shell's settings, in three sections. Each choice applies at once and is remembered.
//   Shell  the island's size, shape and hiding (and what stays of it then), "Activate Linux"
//   Idle   what happens with no input (modules/lock/Idle.qml)
//   Lock   what the lock screen shows (modules/lock/LockConfig.qml)
// Colours and the wallpaper are in views/Theme.qml; the glass is Hyprland's (hypr/modules/look.lua).
// Keys: S I L sections, arrows/Tab move, Left/Right step a slider, Enter/Space choose, T theme,
// Backspace back, Escape closes.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 440
    property string section: "shell"

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    component Label: Text {
        leftPadding: 4
        color: Config.primary
        font.family: Config.font
        font.pixelSize: Config.body
        font.weight: Font.DemiBold
    }

    // a line with a switch at its end
    component Switch: Item {
        id: line
        property string text: ""
        property alias checked: toggle.checked
        signal toggled(bool on)

        width: parent.width
        height: 40

        Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: line.text
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.body + 1
        }
        Toggle {
            id: toggle
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            onToggled: on => line.toggled(on)
        }
    }

    // the waits an idle step can have, in seconds; 0 = never, at the far end of the slider
    readonly property var stops: [30, 60, 120, 180, 300, 600, 900, 1200, 1800, 2700, 3600, 7200, 0]
    function stopOf(seconds) {
        if (seconds <= 0) return stops.length - 1
        let best = 0
        for (let i = 0; i < stops.length - 1; i++)
            if (Math.abs(stops[i] - seconds) < Math.abs(stops[best] - seconds)) best = i
        return best
    }
    function spoken(seconds) {
        if (seconds <= 0) return "Never"
        const h = Math.floor(seconds / 3600), m = Math.floor(seconds % 3600 / 60), s = seconds % 60
        return [h && h + " h", m && m + " min", s && s + " s"].filter(Boolean).join(" ")
    }

    // one idle step: what it does, and a slider for how long before it does
    component Delay: Row {
        id: delay
        property string text: ""
        property alias icon: wait.icon
        property int seconds: 0
        signal picked(int seconds)

        width: parent.width
        spacing: 12

        Text {
            id: caption
            width: 104
            leftPadding: 4
            anchors.verticalCenter: parent.verticalCenter
            text: delay.text
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.body + 1
        }
        Slider {
            id: wait
            readonly property int last: root.stops.length - 1
            width: parent.width - caption.width - parent.spacing
            value: root.stopOf(delay.seconds) / last
            // the real value, which may be no stop (the defaults, or one set over IPC)
            valueText: root.spoken(dragging ? root.stops[Math.round(shown * last)] : delay.seconds)
            step: 1 / last
            onCommitted: v => delay.picked(root.stops[Math.round(v * last)])
        }
    }

    // a text field that takes its keys (ViewLoader never sees them) and gives Escape and Backspace
    // back what they mean in a view
    component Field: SearchBar {
        width: parent.width
        height: 52
        fieldSize: Config.body
        onKey: Engine.key()
        onEscaped: Engine.close()
        onBackspaceEmpty: Engine.back()
    }

    // a picture's path: applied on Enter and on leaving the field
    property string pathError: ""
    component PathField: Field {
        id: path
        property string setting: ""
        text: LockConfig[setting]
        function apply() { root.pathError = LockConfig.setPicture(setting, text.trim()) }
        onAccepted: apply()

        Connections {
            target: path.field
            function onActiveFocusChanged() { if (!path.field.activeFocus && path.text !== LockConfig[path.setting]) path.apply() }
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: 14

        Header {
            width: parent.width
            title: "Settings"
            subtitle: root.section === "idle"
                      ? (!Idle.enabled ? "Stays on" : Toggles.caffeine ? "Caffeine: stays on" : "Locks after " + root.spoken(Idle.lockAfter))
                      : root.section === "lock" ? LockConfig.shownName + "  ·  " + LockConfig.shownInfo
                      : (Config.style === "notch" ? "Notch" : "Floating") + "  ·  " + Math.round(Config.scale * 100) + " %"
                        + (Engine.autoHide ? "  ·  Hides when not in use" : "")
            onBack: Engine.back()

            Pill { kind: "text"; icon: Config.symbol.theme; iconSize: 22; shortcut: "t"; onClicked: Engine.open(Engine.View.Theme) }
        }

        Segmented {
            width: parent.width
            options: [{ key: "shell", label: "Shell", shortcut: "s" },
                      { key: "idle", label: "Idle", shortcut: "i" },
                      { key: "lock", label: "Lock", shortcut: "l" }]
            current: root.section
            onPicked: key => root.section = key
        }

        // ---- Shell ----
        Column {
            visible: root.section === "shell"
            width: parent.width
            spacing: 14

            Label { text: "Size"; topPadding: 6 }
            Row {
                width: parent.width
                spacing: 10

                // applied on release (or per key step): the island rescales under the slider
                Slider {
                    id: size
                    width: parent.width - (reset.visible ? reset.width + parent.spacing : 0)
                    focus: true                              // the keyboard starts here
                    icon: "format_size"
                    value: (Config.scale - 0.8) / 0.6
                    valueText: Math.round((0.8 + shown * 0.6) * 100) + "%"
                    step: 0.05 / 0.6
                    onCommitted: v => Config.scale = Math.round((0.8 + v * 0.6) * 20) / 20
                }
                Pill {
                    id: reset
                    visible: Math.abs(Config.scale - 1) > 0.001
                    implicitHeight: 52
                    kind: "text"
                    text: "Reset"
                    onClicked: Config.scale = 1
                }
            }

            Label { text: "Island"; topPadding: 4 }
            Segmented {
                width: parent.width
                options: [{ key: "pill", label: "Floating" }, { key: "notch", label: "Notch" }]
                current: Config.style
                onPicked: key => Config.style = key
            }

            Switch {
                text: "Hide when not in use"
                checked: Engine.autoHide
                onToggled: on => Engine.setAutoHide(on)
            }
            // what stays at the top edge while it's hidden
            Segmented {
                visible: Engine.autoHide
                width: parent.width
                options: [{ key: "strip", label: "Handle when hidden" }, { key: "none", label: "No handle" }]
                current: Config.handle
                onPicked: key => Config.handle = key
            }

            Label { text: "Desktop"; topPadding: 4 }
            Switch {
                text: "\"Activate Linux\""
                checked: Config.activateLinux
                onToggled: on => Config.activateLinux = on
            }
        }

        // ---- Idle ----
        Column {
            visible: root.section === "idle"
            width: parent.width
            spacing: 14

            Switch {
                text: "When there's no input"
                checked: Idle.enabled
                onToggled: on => Idle.enabled = on
            }
            Delay {
                enabled: Idle.enabled
                text: "Dim"
                icon: "brightness_low"
                seconds: Idle.dimAfter
                onPicked: s => Idle.dimAfter = s
            }
            Delay {
                enabled: Idle.enabled
                text: "Lock"
                icon: "lock"
                seconds: Idle.lockAfter
                onPicked: s => Idle.lockAfter = s
            }
            Delay {
                enabled: Idle.enabled
                text: "Screens off"
                icon: "desktop_access_disabled"
                seconds: Idle.offAfter
                onPicked: s => Idle.offAfter = s
            }
            Delay {
                enabled: Idle.enabled
                text: "Suspend"
                icon: "bedtime"
                seconds: Idle.suspendAfter
                onPicked: s => Idle.suspendAfter = s
            }

            // the same switch as the dashboard's tile: while it's on, none of the above runs
            Switch {
                visible: Toggles.has("systemd-inhibit")
                text: "Caffeine: stay awake for now"
                checked: Toggles.caffeine
                onToggled: on => Toggles.caffeine = on
            }
        }

        // ---- Lock ----
        Column {
            visible: root.section === "lock"
            width: parent.width
            spacing: 10

            Label { text: "Pictures"; topPadding: 6 }
            PathField {
                setting: "image"
                icon: Config.symbol.wallpaper
                placeholder: "Background: follows the wallpaper"

                // pin the wallpaper showing now
                Pill {
                    implicitHeight: 38
                    kind: "text"
                    icon: "keep"
                    iconSize: 20
                    shortcut: "w"
                    onClicked: { root.pathError = ""; LockConfig.image = Wallpaper.current }
                }
            }
            PathField {
                setting: "avatar"
                icon: "person"
                placeholder: "Profile picture: a path, GIFs play"
            }
            Segmented {
                width: parent.width
                options: [{ key: "circle", label: "Circle" }, { key: "square", label: "Square" }]
                current: LockConfig.avatarShape
                onPicked: key => LockConfig.avatarShape = key
            }
            Text {
                visible: root.pathError !== ""
                width: parent.width
                leftPadding: 4
                elide: Text.ElideMiddle
                text: root.pathError
                color: Config.bad
                font.family: Config.font
                font.pixelSize: Config.small
            }

            Label { text: "Who"; topPadding: 6 }
            Field {
                text: LockConfig.name
                icon: "badge"
                placeholder: LockConfig.fullName || LockConfig.user
                onTextChanged: LockConfig.name = text
            }
            Field {
                text: LockConfig.info
                icon: "info"
                placeholder: LockConfig.defaultInfo
                onTextChanged: LockConfig.info = text
            }
        }

        KeyHints {
            width: parent.width
            keys: root.section === "lock" ? [["⏎", "apply"], ["Esc", "close"]]
                : [["← →", root.section === "idle" ? "wait" : "size"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
