import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The island's colours (views/Theme.qml has the palettes as a footer; this is everything). Each
// choice applies at once and is remembered (components/Config.qml).
//   where they come from   Presets: the palettes, each as a card in its own colours
//                          Accent: a scheme generated from a colour, one of twelve or any hex
//                          Wallpaper: generated from the wallpaper; another of its colours can be
//                          the accent
//   Style (generated schemes): tonal, vibrant, muted or mono · Mode: dark or light (with a preset,
//   light is Paper and dark the last dark palette)
// Keys: P A W where the colours come from, arrows/Tab move, Enter/Space choose, Backspace back,
// Escape closes.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 600
    readonly property bool generated: Config.source !== "preset"
    readonly property var seeds: ["#d0453b", "#e0822a", "#d9a400", "#8db600", "#3f9b4f", "#2a9d8f",
                                  "#1e9fc4", "#3b6fd8", "#5b5bd6", "#8a4fd0", "#c84f9b", "#8d6e63"]
    readonly property var styles: [
        { key: "tonal",   label: "Tonal" },
        { key: "vibrant", label: "Vibrant" },
        { key: "muted",   label: "Muted" },
        { key: "mono",    label: "Mono" }
    ]

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    component Label: Text {
        leftPadding: 4
        color: Config.primary
        font.family: Config.font
        font.pixelSize: Config.body
        font.weight: Font.DemiBold
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 14

        Header {
            width: parent.width
            title: "Colours"
            subtitle: !root.generated ? Config.current.label + "  ·  a preset"
                    : (Config.source === "accent" ? "From " + Config.hex(Config.accent) : "From the wallpaper")
                      + "  ·  " + root.styles.find(s => s.key === Config.variant).label
                      + "  ·  " + (Config.darkMode ? "Dark" : "Light")
            onBack: Engine.back()
        }

        Segmented {
            width: parent.width
            options: [
                { key: "preset",    label: "Presets",   icon: "palette",   shortcut: "p" },
                { key: "accent",    label: "Accent",    icon: "colorize",  shortcut: "a" },
                { key: "wallpaper", label: "Wallpaper", icon: "wallpaper", shortcut: "w" }
            ]
            current: Config.source
            onPicked: key => Config.source = key
        }

        // ================= presets: each palette in its own colours =================
        Grid {
            visible: Config.source === "preset"
            columns: 4
            spacing: 12

            Repeater {
                model: Config.names

                Tile {
                    id: card
                    required property string modelData
                    readonly property var p: Config.palettes[modelData]

                    width: (column.width - 36) / 4
                    height: 112
                    padding: 14
                    tint: p.surface
                    current: Config.name === modelData
                    // a hairline, so a palette as dark as the island still has an edge
                    border.width: current ? 2 : 1
                    border.color: current ? Config.primary : Config.divider
                    focus: current && Config.source === "preset"   // the keyboard starts on the palette in use
                    onClicked: Config.name = modelData

                    Text {
                        anchors { left: parent.left; top: parent.top }
                        text: card.p.label
                        color: card.p.text
                        font.family: Config.font
                        font.pixelSize: Config.body
                        font.weight: Font.DemiBold
                    }
                    Icon {
                        anchors { right: parent.right; top: parent.top }
                        visible: card.current
                        name: "check_circle"
                        filled: true
                        size: 20
                        color: card.p.primary
                    }

                    // what the island looks like in it: a line of text, a dimmer one, an "on" pill
                    // and a selected chip
                    Column {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        spacing: 6

                        Rectangle { width: parent.width * 0.7; height: 6; radius: 3; color: card.p.text; opacity: 0.85 }
                        Rectangle { width: parent.width * 0.45; height: 6; radius: 3; color: card.p.dim; opacity: 0.7 }
                        Row {
                            topPadding: 4
                            spacing: 6
                            Rectangle { width: 40; height: 18; radius: 9; color: card.p.primary }
                            Rectangle { width: 28; height: 18; radius: 9; color: card.p.secondary }
                            Rectangle { width: 18; height: 18; radius: 9; color: card.p.container }
                        }
                    }
                }
            }
        }

        // ================= an accent you pick =================
        Row {
            visible: Config.source === "accent"
            spacing: (column.width - 12 * 40) / 11

            Repeater {
                model: root.seeds

                Swatch {
                    required property string modelData
                    width: 40; height: 40
                    tone: modelData
                    chosen: Qt.colorEqual(Config.accent, modelData)
                    focus: chosen && Config.source === "accent"
                    onPicked: Config.accent = modelData
                }
            }
        }
        Row {
            visible: Config.source === "accent"
            width: parent.width
            spacing: 12

            Rectangle {
                width: parent.width - preview.width - parent.spacing
                height: 52
                radius: height / 2
                color: Config.high
                border.width: field.activeFocus ? 2 : 0
                border.color: Config.primary

                TextInput {
                    id: field
                    anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                    verticalAlignment: TextInput.AlignVCenter
                    activeFocusOnTab: true
                    color: Config.text
                    font.family: Config.mono
                    font.pixelSize: Config.large
                    maximumLength: 7
                    validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,6}/ }
                    clip: true

                    readonly property string digits: text.replace("#", "")
                    function apply() {
                        if (digits.length === 6) { Config.accent = "#" + digits; text = "" }
                    }
                    // the field accepts its keys, so ViewLoader never sees them: report them here
                    Keys.onPressed: event => { Engine.key(); event.accepted = false }
                    Keys.onReturnPressed: apply()
                    Keys.onEnterPressed:  apply()

                    Text {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Any colour: hex, e.g. " + Config.hex(Config.accent)
                        color: Config.dim
                        font.family: Config.font
                        font.pixelSize: Config.body
                    }
                }
            }
            Rectangle {
                id: preview
                width: 52; height: 52; radius: 26
                color: field.digits.length === 6 ? "#" + field.digits : Config.accent
                border.width: 1
                border.color: Config.outline
            }
        }

        // ================= the wallpaper's colours =================
        Row {
            visible: Config.source === "wallpaper"
            width: parent.width
            spacing: 16

            ClippingRectangle {
                width: 176
                height: 110
                radius: Config.innerRadius
                color: Config.container

                Image {
                    anchors.fill: parent
                    source: Wallpaper.current ? Wallpaper.fileUrl(Wallpaper.current) : ""
                    sourceSize: Qt.size(352, 220)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
            Column {
                width: parent.width - 176 - parent.spacing
                spacing: 12

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: Wallpaper.swatches.length > 0
                        ? "Picked from your wallpaper. Choose another of its colours to make it the accent."
                        : "No wallpaper colours yet"
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
                Flow {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: Wallpaper.swatches

                        Swatch {
                            required property color modelData
                            width: 36; height: 36
                            tone: modelData
                            chosen: Qt.colorEqual(Wallpaper.seed, modelData)
                            onPicked: {
                                Config.accent = modelData
                                Config.source = "accent"
                            }
                        }
                    }
                }
            }
        }

        // ================= style and mode =================
        Rectangle {
            width: parent.width
            height: 1
            color: Config.divider
        }

        Row {
            width: parent.width
            spacing: 16

            // a generated scheme's style
            Column {
                visible: root.generated
                width: parent.width - mode.width - parent.spacing
                spacing: 10

                Label { text: "Style" }
                Segmented {
                    width: parent.width
                    options: root.styles
                    current: Config.variant
                    onPicked: key => Config.variant = key
                }
            }
            Column {
                id: mode
                width: root.generated ? 220 : parent.width
                spacing: 10

                Label { text: "Mode" }
                Segmented {
                    width: parent.width
                    options: [{ key: "dark", label: "Dark", icon: "dark_mode" }, { key: "light", label: "Light", icon: "light_mode" }]
                    current: Config.dark ? "dark" : "light"
                    onPicked: key => { Config.setDark(key === "dark"); Toggles.colorScheme(Config.dark) }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["⌫", "back"], ["Esc", "close"]]
        }
    }
}
