import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.lock
import qs.modules.services

Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 440
    property string section: "shell"

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    component Switch: Item {
        id: line
        property string text: ""
        property alias checked: toggle.checked
        signal toggled(bool on)

        width: parent.width
        height: 40

        Label {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: line.text
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

    component Delay: Row {
        id: delay
        property string text: ""
        property alias icon: wait.icon
        property int seconds: 0
        signal picked(int seconds)

        width: parent.width
        spacing: 12

        Label {
            id: caption
            width: 104
            leftPadding: 4
            anchors.verticalCenter: parent.verticalCenter
            text: delay.text
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
                      ? (!Idle.enabled ? "Stays on" : Toggles.caffeine ? "Caffeine: stays on"
                         : Idle.mediaPlaying ? "Media playing: stays on" : "Locks after " + root.spoken(Idle.lockAfter))
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

        Column {
            visible: root.section === "shell"
            width: parent.width
            spacing: 14

            SectionLabel { text: "Size"; topPadding: 6 }
            Row {
                width: parent.width
                spacing: 10

                // applied on release (or per key step): the island rescales under the slider
                Slider {
                    id: size
                    width: parent.width - (reset.visible ? reset.width + parent.spacing : 0)
                    focus: true
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

            SectionLabel { text: "Island"; topPadding: 4 }
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
            Segmented {
                visible: Engine.autoHide
                width: parent.width
                options: [{ key: "strip", label: "Handle when hidden" }, { key: "none", label: "No handle" }]
                current: Config.handle
                onPicked: key => Config.handle = key
            }

            SectionLabel { text: "Desktop"; topPadding: 4 }
            Switch {
                text: "\"Activate Linux\""
                checked: Config.activateLinux
                onToggled: on => Config.activateLinux = on
            }
        }

        Column {
            visible: root.section === "idle"
            width: parent.width
            spacing: 14

            Switch {
                text: "When there's no input"
                checked: Idle.enabled
                onToggled: on => Idle.enabled = on
            }
            Repeater {
                model: [{ text: "Dim",         icon: "brightness_low",          key: "dimAfter" },
                        { text: "Lock",        icon: "lock",                    key: "lockAfter" },
                        { text: "Screens off", icon: "desktop_access_disabled", key: "offAfter" },
                        { text: "Suspend",     icon: "bedtime",                 key: "suspendAfter" }]

                Delay {
                    required property var modelData
                    enabled: Idle.enabled
                    text: modelData.text
                    icon: modelData.icon
                    seconds: Idle[modelData.key]
                    onPicked: s => Idle[modelData.key] = s
                }
            }

            // the same switch as the dashboard's tile: while it's on, none of the above runs
            Switch {
                visible: Toggles.has("systemd-inhibit")
                text: "Caffeine: stay awake for now"
                checked: Toggles.caffeine
                onToggled: on => Toggles.caffeine = on
            }
        }

        Column {
            visible: root.section === "lock"
            width: parent.width
            spacing: 10

            SectionLabel { text: "Pictures"; topPadding: 6 }
            PathField {
                setting: "image"
                icon: Config.symbol.wallpaper
                placeholder: "Background: follows the wallpaper"

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
            Label {
                visible: root.pathError !== ""
                width: parent.width
                leftPadding: 4
                elide: Text.ElideMiddle
                text: root.pathError
                color: Config.bad
                font.pixelSize: Config.small
            }

            SectionLabel { text: "Who"; topPadding: 6 }
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
