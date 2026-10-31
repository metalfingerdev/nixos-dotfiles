import QtQuick
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

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

    component PaletteSwatch: Swatch {
        required property var palette
        width: root.swatch; height: root.swatch
        ring: palette.surface
        tone: palette.primary
    }
    component GeneratedSwatch: PaletteSwatch {
        required property string from
        palette: Config.generated(from)
        chosen: Config.source === from
        onPicked: Config.source = from
    }

    component Section: Item {
        id: section

        property string title: ""
        property string letter: ""                  // the arrow's shortcut
        property int view: -1

        width: parent.width
        height: 40

        SectionLabel {
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

        Section { title: "Colours"; letter: "c"; view: Engine.View.Colours }

        Item {
            width: parent.width
            height: root.swatch

            Row {
                id: swatches
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Repeater {
                    model: Config.names

                    PaletteSwatch {
                        required property string modelData
                        palette: Config.palettes[modelData]
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

                GeneratedSwatch { from: "accent"; icon: "colorize" }
                GeneratedSwatch { from: "wallpaper"; icon: Config.symbol.wallpaper }
            }

            Segmented {
                anchors { left: swatches.right; leftMargin: 24; right: parent.right; verticalCenter: parent.verticalCenter }
                height: root.swatch
                options: [{ key: "dark", label: "Dark", icon: "dark_mode" }, { key: "light", label: "Light", icon: "light_mode" }]
                current: Config.dark ? "dark" : "light"
                onPicked: key => { Config.setDark(key === "dark"); Toggles.colorScheme(Config.dark) }
            }
        }

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
            function activate() { Wallpaper.set(Wallpaper.files[currentIndex]) }

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

        Label {
            visible: Wallpaper.files.length === 0
            leftPadding: 4
            text: "No images in " + Wallpaper.dir
            color: Config.dim
        }

        KeyHints {
            width: parent.width
            keys: [["← →", "pick"], ["↵", "apply"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
