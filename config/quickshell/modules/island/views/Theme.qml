import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// How everything looks (also `open settings`). Each choice applies at once and is remembered
// (components/Config.qml; the wallpaper by awww itself).
//   left   Colours: where they come from (a preset palette, an accent you pick, or the
//          wallpaper), then for a generated scheme its style and dark or light
//   right  Size of the whole island, its shape and handle, frosted glass, and the wallpaper
// Keys: arrows/Tab move, Enter/Space choose, R random wallpaper, Escape back. On the wallpaper
// strip, Left/Right pick and Enter applies.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 440
    readonly property int gutter: 28
    readonly property var seeds: ["#d0453b", "#e0822a", "#d9a400", "#8db600", "#3f9b4f", "#2a9d8f",
                                  "#1e9fc4", "#3b6fd8", "#5b5bd6", "#8a4fd0", "#c84f9b", "#8d6e63"]

    implicitWidth: 2 * colW + gutter + 2 * pad
    implicitHeight: Math.max(colours.implicitHeight, look.implicitHeight) + header.height + 20 + 2 * pad

    component Label: Text {
        leftPadding: 4
        color: Config.primary
        font.family: Config.font
        font.pixelSize: Config.body
        font.weight: Font.DemiBold
    }

    // a round colour to pick: focusable, a check when it's the one in use
    component Swatch: Rectangle {
        id: swatch
        property color tone: "grey"
        property bool chosen: false
        signal picked()
        function activate() { picked() }

        width: 52
        height: 52
        radius: width / 2
        color: tone
        border.width: 2
        border.color: Qt.rgba(1, 1, 1, 0.12)
        activeFocusOnTab: true
        Keys.onReturnPressed: picked()
        Keys.onEnterPressed:  picked()
        Keys.onSpacePressed:  picked()

        Icon {
            anchors.centerIn: parent
            visible: swatch.chosen
            name: "check"
            size: 26
            color: swatch.tone.hslLightness > 0.6 ? "#000000" : "#ffffff"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: swatch.picked()
        }
        FocusRing {}
    }

    function hex(c) {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0")
        return "#" + h(c.r) + h(c.g) + h(c.b)
    }

    Header {
        id: header
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        title: "Theme"
        subtitle: (Config.source === "preset" ? Config.current.label
                 : Config.source === "accent" ? "From " + root.hex(Config.accent) : "From the wallpaper")
                + (Wallpaper.current ? "  ·  " + Wallpaper.baseName(Wallpaper.current) : "")
        onBack: Engine.back()
    }

    // ================= left: colours =================
    Column {
        id: colours
        x: root.pad
        y: header.y + header.height + 20
        width: root.colW
        spacing: 14

        Label { text: "Colours" }

        Segmented {
            width: parent.width
            options: [
                { key: "preset",    label: "Presets",   icon: "palette" },
                { key: "accent",    label: "Accent",    icon: "colorize" },
                { key: "wallpaper", label: "Wallpaper", icon: "wallpaper" }
            ]
            current: Config.source
            onPicked: key => Config.source = key
        }

        // ---- presets ----
        Grid {
            visible: Config.source === "preset"
            columns: 4
            spacing: 12

            Repeater {
                model: Config.names

                Tile {
                    id: tile
                    required property string modelData
                    readonly property var p: Config.palettes[modelData]

                    width: (colours.width - 36) / 4
                    height: 92
                    padding: 12
                    tint: p.surface
                    current: Config.name === modelData
                    focus: current && Config.source === "preset"   // the keyboard starts on the palette in use
                    onClicked: Config.name = modelData

                    Text {
                        anchors { left: parent.left; top: parent.top }
                        text: tile.p.label
                        color: tile.p.text
                        font.family: Config.font
                        font.pixelSize: Config.body
                        font.weight: Font.DemiBold
                    }
                    // primary, secondary, container: the colours the island is made of
                    Row {
                        anchors { left: parent.left; bottom: parent.bottom }
                        spacing: -6

                        Repeater {
                            model: [tile.p.primary, tile.p.secondary, tile.p.container]

                            Rectangle {
                                required property string modelData
                                width: 24; height: 24; radius: 12
                                color: modelData
                                border.width: 2
                                border.color: tile.p.surface
                            }
                        }
                    }
                }
            }
        }

        // ---- an accent you pick ----
        Grid {
            visible: Config.source === "accent"
            columns: 6
            spacing: (colours.width - 6 * 52) / 5

            Repeater {
                model: root.seeds

                Swatch {
                    required property string modelData
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

                    function apply() {
                        const t = text.replace("#", "")
                        if (t.length === 6) { Config.accent = "#" + t; text = "" }
                    }
                    // the field accepts its keys, so ViewLoader never sees them: report them here
                    Keys.onPressed: event => { Engine.key(); event.accepted = false }
                    Keys.onReturnPressed: apply()
                    Keys.onEnterPressed:  apply()

                    Text {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Hex colour, e.g. " + root.hex(Config.accent)
                        color: Config.dim
                        font.family: Config.font
                        font.pixelSize: Config.body
                    }
                }
            }
            Rectangle {
                id: preview
                width: 52; height: 52; radius: 26
                color: field.text.replace("#", "").length === 6 ? "#" + field.text.replace("#", "") : Config.accent
                border.width: 2
                border.color: Config.outline
            }
        }

        // ---- the wallpaper's colours ----
        Row {
            visible: Config.source === "wallpaper"
            width: parent.width
            spacing: 16

            ClippingRectangle {
                width: 168
                height: 108
                radius: Config.innerRadius + 4
                color: Config.container

                Image {
                    anchors.fill: parent
                    source: Wallpaper.current ? Wallpaper.fileUrl(Wallpaper.current) : ""
                    sourceSize: Qt.size(336, 216)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
            Column {
                width: parent.width - 168 - parent.spacing
                spacing: 10

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: Wallpaper.swatches.length > 0
                        ? "Picked from your wallpaper. Choose another of its colours to use it as the accent."
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
                            width: 40; height: 40
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

        // ---- a generated scheme's style ----
        Label { visible: Config.source !== "preset"; text: "Style"; topPadding: 4 }
        Segmented {
            visible: Config.source !== "preset"
            width: parent.width
            options: [
                { key: "tonal",   label: "Tonal" },
                { key: "vibrant", label: "Vibrant" },
                { key: "muted",   label: "Muted" },
                { key: "mono",    label: "Mono" }
            ]
            current: Config.variant
            onPicked: key => Config.variant = key
        }
        Segmented {
            visible: Config.source !== "preset"
            width: parent.width
            options: [{ key: "dark", label: "Dark", icon: "dark_mode" }, { key: "light", label: "Light", icon: "light_mode" }]
            current: Config.darkMode ? "dark" : "light"
            onPicked: key => { Config.darkMode = key === "dark"; Toggles.colorScheme(Config.darkMode) }
        }
    }

    // ================= right: size, the island, wallpaper =================
    Column {
        id: look
        x: root.pad + root.colW + root.gutter
        y: colours.y
        width: root.colW
        spacing: 14

        Label { text: "Size" }
        Row {
            width: parent.width
            spacing: 10

            // applied on release (or per key step): the island rescales under the slider
            Slider {
                id: size
                width: parent.width - (reset.visible ? reset.width + parent.spacing : 0)
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
        Segmented {
            width: parent.width
            options: [{ key: "strip", label: "Handle when hidden" }, { key: "none", label: "No handle" }]
            current: Config.handle
            onPicked: key => Config.handle = key
        }

        Item {
            width: parent.width
            height: 40

            Text {
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: "Frosted glass"
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.body + 1
            }
            Toggle {
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                checked: Config.glass
                onToggled: on => Config.glass = on
            }
        }
        // opacity: 20 % .. 100 %
        Slider {
            visible: Config.glass
            width: parent.width
            icon: "opacity"
            value: (Config.glassOpacity - 0.2) / 0.8
            valueText: Math.round(Config.glassOpacity * 100) + "%"
            onMoved: v => Config.glassOpacity = 0.2 + v * 0.8
        }

        // ---- wallpaper ----
        Item {
            width: parent.width
            height: 48

            Label {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Wallpaper"
            }
            Pill {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: Wallpaper.files.length > 1
                icon: "shuffle"
                text: "Random"
                shortcut: "r"
                onClicked: Wallpaper.random()
            }
        }

        Text {
            visible: Wallpaper.files.length === 0
            leftPadding: 4
            text: "No images in " + Wallpaper.dir
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        ListView {
            id: strip

            visible: Wallpaper.files.length > 0
            width: parent.width
            height: 96
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpaper.files
            highlightMoveDuration: 150
            currentIndex: Math.max(0, Wallpaper.currentIndex)
            Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Center)

            // the list takes its keys itself, so ViewLoader never sees them: report them here
            Keys.onPressed: event => { Engine.key(); event.accepted = false }
            Keys.onLeftPressed:   decrementCurrentIndex()
            Keys.onRightPressed:  incrementCurrentIndex()
            Keys.onReturnPressed: Wallpaper.set(Wallpaper.files[currentIndex])
            Keys.onEnterPressed:  Wallpaper.set(Wallpaper.files[currentIndex])
            activeFocusOnTab: true

            // the wheel scrolls sideways
            WheelHandler {
                onWheel: e => {
                    const d = e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x
                    strip.contentX = Math.max(0, Math.min(Math.max(0, strip.contentWidth - strip.width), strip.contentX - d))
                }
            }

            delegate: ClippingRectangle {
                id: thumb
                required property string modelData
                required property int index
                readonly property bool applied: modelData === Wallpaper.current

                width: 150
                height: 96
                radius: Config.innerRadius
                color: Config.container

                Image {
                    anchors.fill: parent
                    source: Wallpaper.fileUrl(thumb.modelData)
                    sourceSize: Qt.size(300, 192)            // decode small: wallpapers are big
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // applied: a primary ring and a check; the keyboard's pick: a thick ring
                Rectangle {
                    anchors.fill: parent
                    radius: thumb.radius
                    color: "transparent"
                    border.width: strip.activeFocus && Config.focusVisible && thumb.ListView.isCurrentItem ? 4
                                : thumb.applied ? 3 : 0
                    border.color: thumb.applied && !(strip.activeFocus && thumb.ListView.isCurrentItem) ? Config.primary : Config.text
                }
                Rectangle {
                    visible: thumb.applied
                    anchors { right: parent.right; top: parent.top; margins: 8 }
                    width: 24; height: 24; radius: 12
                    color: Config.primary

                    Icon {
                        anchors.centerIn: parent
                        name: "check"
                        size: 16
                        color: Config.primaryInk
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { strip.currentIndex = thumb.index; Wallpaper.set(thumb.modelData) }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["R", "random wallpaper"], ["Esc", "back"]]
        }
    }
}
