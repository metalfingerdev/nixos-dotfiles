import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The island's colours (views/Theme.qml has them as one row; this is everything). Each choice
// applies at once and is remembered (components/Config.qml).
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
            subtitle: Config.source === "preset" ? Config.current.label
                    : Config.source === "accent" ? "From " + Config.hex(Config.accent) : "From the wallpaper"
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
                    // primary, secondary, container: the colours the island is made of
                    Row {
                        anchors { left: parent.left; bottom: parent.bottom }
                        spacing: -6

                        Repeater {
                            model: [card.p.primary, card.p.secondary, card.p.container]

                            Rectangle {
                                required property string modelData
                                width: 24; height: 24; radius: 12
                                color: modelData
                                border.width: 2
                                border.color: card.p.surface
                            }
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
        // any colour: the field, with the colour it would be at its start (a search bar's badge)
        Rectangle {
            visible: Config.source === "accent"
            width: parent.width
            height: 52
            radius: height / 2
            color: Config.high
            border.width: field.activeFocus ? 2 : 0
            border.color: Config.primary

            Rectangle {
                id: badge
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height - 12
                height: width
                radius: width / 2
                color: field.digits.length === 6 ? "#" + field.digits : Config.accent
                border.width: 1
                border.color: Config.outline
            }

            TextInput {
                id: field
                anchors { left: badge.right; leftMargin: 14; right: parent.right; rightMargin: 20; top: parent.top; bottom: parent.bottom }
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
                    text: "Any colour, e.g. " + Config.hex(Config.accent)
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
            }
        }

        // ================= the wallpaper's colours: a click makes one the accent =================
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
            Flow {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 176 - parent.spacing
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
                Text {
                    visible: Wallpaper.swatches.length === 0
                    text: "No wallpaper colours yet"
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
            }
        }

        // ================= style and mode =================
        Row {
            width: parent.width
            spacing: 16

            // a generated scheme's style
            Column {
                visible: root.generated
                width: parent.width - mode.width - parent.spacing
                spacing: 10

                Label { text: "Style"; topPadding: 4 }
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

                Label { text: "Mode"; topPadding: 4 }
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
