import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The island's colours (views/Theme.qml has them as one row; this is everything). Each choice
// applies at once and is remembered (components/Config.qml).
//   where they come from   Presets: the palettes, each as a card in its own colours
//                          Accent: any colour: the map (hue and lightness), its saturation, or a hex
//                          Wallpaper: generated from the wallpaper; a click makes another of its
//                          colours the one it's generated from (it stays on the wallpaper), and
//                          sliders set how saturated and light that comes out
//   Surface tint (generated schemes): how much of the colour goes into the island's surfaces
//   Mode: dark or light (with a preset, light is Paper and dark the last dark palette)
// Keys: P A W where the colours come from, Tab moves, arrows step the map and the sliders,
// Enter/Space choose, Backspace back, Escape closes.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 780
    readonly property bool generated: Config.source !== "preset"
    readonly property bool accent: Config.source === "accent"
    readonly property bool wallpaper: Config.source === "wallpaper"

    // The accent as the map and its slider hold it. Kept apart from Config.accent because a colour
    // forgets: white has no hue, grey no saturation, and the handle mustn't jump when it gets there.
    property real hue: 0
    property real saturation: 1
    property real lightness: 0.5

    function loadAccent() {
        const c = Config.accent
        if (c.hslHue >= 0) hue = c.hslHue
        saturation = c.hslSaturation
        lightness = c.hslLightness
    }
    function setAccent() {
        Config.accent = Qt.hsla(hue, saturation, lightness, 1)
        Engine.key()
    }
    Component.onCompleted: loadAccent()
    // it changed elsewhere: the hex field, IPC
    Connections {
        target: Config
        function onAccentChanged() {
            if (Config.hex(Config.accent) !== Config.hex(Qt.hsla(root.hue, root.saturation, root.lightness, 1))) root.loadAccent()
        }
    }

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // a slider that names what it sets, at its far end
    component Level: Slider {
        id: level
        property string title: ""
        valueText: title + "  " + Math.round(level.shown * 100) + "%"
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
                    : root.accent ? "From " + Config.hex(Config.accent) : "From the wallpaper"
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

        // ================= an accent you pick: every colour there is =================
        ColourMap {
            visible: root.accent
            width: parent.width
            height: 260
            focus: root.accent                       // the keyboard starts on the map
            hue: root.hue
            lightness: root.lightness
            saturation: root.saturation
            onMoved: (h, l) => { root.hue = h; root.lightness = l; root.setAccent() }
        }

        // ================= the wallpaper's colours: a click generates the scheme from that one =================
        Row {
            visible: root.wallpaper
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
                        width: 44; height: 44
                        tone: modelData
                        chosen: Config.hex(Wallpaper.seed) === Config.hex(modelData)
                        focus: chosen && root.wallpaper
                        onPicked: Wallpaper.pick(modelData)
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

        // ================= how that colour is used =================
        Row {
            id: levels
            readonly property real each: (width - (root.wallpaper ? 2 : 1) * spacing) / (root.wallpaper ? 3 : 2)

            visible: root.generated
            width: parent.width
            spacing: 12

            Level {
                width: levels.each
                title: "Saturation"
                icon: "invert_colors"
                value: root.accent ? root.saturation : Config.wallpaperSaturation
                onMoved: v => {
                    if (root.accent) { root.saturation = v; root.setAccent() }
                    else { Config.wallpaperSaturation = v; Engine.key() }
                }
            }
            Level {
                visible: root.wallpaper
                width: levels.each
                title: "Lightness"
                icon: "brightness_6"
                value: Config.wallpaperLightness
                onMoved: v => { Config.setWallpaperLightness(v); Engine.key() }
            }
            Level {
                width: levels.each
                title: "Surface tint"
                icon: "format_color_fill"
                value: Config.tint
                onMoved: v => { Config.tint = v; Engine.key() }
            }
        }

        // ================= any colour by its number, and the mode =================
        Row {
            width: parent.width
            spacing: 12

            // the field, with the colour it would be at its start (a search bar's badge)
            Rectangle {
                visible: root.accent
                width: parent.width - mode.width - parent.spacing
                height: mode.height
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
                    anchors { left: badge.right; leftMargin: 12; right: parent.right; rightMargin: 20; top: parent.top; bottom: parent.bottom }
                    verticalAlignment: TextInput.AlignVCenter
                    activeFocusOnTab: true
                    color: Config.text
                    font.family: Config.mono
                    font.pixelSize: Config.body + 1
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
                        text: Config.hex(Config.accent)
                        color: Config.dim
                        font: field.font
                    }
                }
            }
            Segmented {
                id: mode
                width: root.accent ? 240 : parent.width
                options: [{ key: "dark", label: "Dark", icon: "dark_mode" }, { key: "light", label: "Light", icon: "light_mode" }]
                current: Config.dark ? "dark" : "light"
                onPicked: key => { Config.setDark(key === "dark"); Toggles.colorScheme(Config.dark) }
            }
        }

        KeyHints {
            width: parent.width
            keys: root.accent ? [["← → ↑ ↓", "colour"], ["Tab", "next"], ["⌫", "back"], ["Esc", "close"]]
                              : [["⌫", "back"], ["Esc", "close"]]
        }
    }
}
