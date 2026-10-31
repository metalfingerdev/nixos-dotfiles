import QtQuick
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// The theme at a glance, as wide as the wallpapers' view:
//   Colours     one row: every preset (its primary inside its surface), then a scheme from the
//               accent or from the wallpaper; dark or light beside it
//   Wallpaper   the images in one large row, the one showing in the middle
// A click on a colour, the mode or a wallpaper applies it at once. Each section's round arrow (the
// one a quick settings tile has when the setting has a view of its own) opens its full view:
// Colours (views/Colours.qml: any accent, the wallpaper's colours, how they're used) and Wallpaper
// (views/Wallpapers.qml, every image). The island's size, shape and hiding are in views/Settings.qml.
// Keys: C colours, W wallpapers, I settings, arrows/Tab move (in the row Left/Right pick and
// Enter/Space apply), Backspace back, Escape closes.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 840
    readonly property int thumbW: 256
    readonly property int thumbH: 160
    readonly property int gap: 12
    readonly property int swatch: 48               // as tall as the mode's segmented button

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    component Label: Text {
        leftPadding: 4
        color: Config.primary
        font.family: Config.font
        font.pixelSize: Config.body
        font.weight: Font.DemiBold
    }

    // a section's title, and the way into its full view: a round arrow at the end of the line
    component Section: Item {
        id: section

        property string title: ""
        property string letter: ""                  // the arrow's shortcut
        property int view: -1

        width: parent.width
        height: 40

        Label {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: section.title
        }
        Pill {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            implicitHeight: 40
            icon: Config.symbol.open
            shortcut: section.letter
            onClicked: Engine.open(section.view)
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 14

        Header {
            width: parent.width
            title: "Theme"
            subtitle: (Config.source === "preset" ? Config.current.label
                     : Config.source === "accent" ? "From " + Config.hex(Config.accent) : "From the wallpaper")
                    + (Wallpaper.current ? "  ·  " + Wallpaper.baseName(Wallpaper.current) : "")
            onBack: Engine.back()

            Pill { kind: "text"; icon: Config.symbol.settings; iconSize: 22; shortcut: "i"; onClicked: Engine.open(Engine.View.Settings) }
        }

        // ================= the colours: one row =================
        Section { title: "Colours"; letter: "c"; view: Engine.View.Colours }

        Item {
            width: parent.width
            height: root.swatch

            Row {
                id: swatches
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // every preset: its primary inside its surface
                Repeater {
                    model: Config.names

                    Swatch {
                        required property string modelData
                        readonly property var p: Config.palettes[modelData]
                        width: root.swatch; height: root.swatch
                        ring: p.surface
                        tone: p.primary
                        chosen: Config.source === "preset" && Config.name === modelData
                        onPicked: { Config.name = modelData; Config.source = "preset" }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 28
                    color: Config.divider
                }

                // or a scheme generated from the accent, or from the wallpaper, drawn the same way
                Swatch {
                    readonly property var p: Config.generated("accent")
                    width: root.swatch; height: root.swatch
                    ring: p.surface
                    tone: p.primary
                    icon: "colorize"
                    chosen: Config.source === "accent"
                    onPicked: Config.source = "accent"
                }
                Swatch {
                    readonly property var p: Config.generated("wallpaper")
                    width: root.swatch; height: root.swatch
                    ring: p.surface
                    tone: p.primary
                    icon: Config.symbol.wallpaper
                    chosen: Config.source === "wallpaper"
                    onPicked: Config.source = "wallpaper"
                }
            }

            Segmented {
                anchors { left: swatches.right; leftMargin: 24; right: parent.right; verticalCenter: parent.verticalCenter }
                height: root.swatch
                options: [{ key: "dark", label: "Dark", icon: "dark_mode" }, { key: "light", label: "Light", icon: "light_mode" }]
                current: Config.dark ? "dark" : "light"
                onPicked: key => { Config.setDark(key === "dark"); Toggles.colorScheme(Config.dark) }
            }
        }

        // ================= the wallpapers: one large row =================
        Section { title: "Wallpaper"; letter: "w"; view: Engine.View.Wallpapers }

        ListView {
            id: strip
            visible: Wallpaper.files.length > 0
            width: parent.width
            height: root.thumbH
            orientation: ListView.Horizontal
            spacing: root.gap
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpaper.files
            currentIndex: Math.max(0, Wallpaper.currentIndex)
            focus: true                                  // the keyboard starts here
            activeFocusOnTab: true
            Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Center)

            // the row moves its own selection with Left/Right (off its ends it lets them go, and
            // ViewLoader moves focus out); report every key, so the countdown restarts
            Keys.onPressed: event => { Engine.key(); event.accepted = false }
            Keys.onReturnPressed: Wallpaper.set(Wallpaper.files[currentIndex])
            Keys.onEnterPressed:  Wallpaper.set(Wallpaper.files[currentIndex])
            Keys.onSpacePressed:  Wallpaper.set(Wallpaper.files[currentIndex])

            // the wheel scrolls the row sideways
            WheelHandler {
                target: null
                onWheel: event => {
                    const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                    strip.contentX = Math.max(strip.originX,
                                     Math.min(strip.originX + strip.contentWidth - strip.width, strip.contentX - d))
                }
            }

            delegate: WallpaperThumb {
                required property string modelData
                required property int index

                width: root.thumbW
                height: root.thumbH
                path: modelData
                picked: strip.activeFocus && ListView.isCurrentItem
                onClicked: { strip.currentIndex = index; Wallpaper.set(modelData) }
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

        KeyHints {
            width: parent.width
            keys: [["← →", "pick"], ["↵", "apply"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
