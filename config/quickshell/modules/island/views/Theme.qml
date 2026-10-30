import QtQuick
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// The theme at a glance: the wallpapers in one large row, the colours as a footer. A click on a
// wallpaper, a palette or the mode applies it at once. Each section's title (a chevron after it)
// is the way into its full view: Wallpaper (views/Wallpapers.qml, every image) and Colours
// (views/Colours.qml: an accent, the wallpaper's colours, style). The island's size, shape and
// hiding are in views/Settings.qml.
// Keys: W wallpapers, C colours, I settings, arrows/Tab move (in the row Left/Right pick and
// Enter/Space apply), Backspace back, Escape closes.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 712
    readonly property int thumbW: 212
    readonly property int thumbH: 132
    readonly property int gap: 12

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // A section's title, and the way into its full view: the title, what's in use, a chevron. The
    // whole line is the link: click it, press Enter/Space on it, or type its shortcut.
    component SectionLink: Rectangle {
        id: link

        property string title: ""
        property string detail: ""
        property string shortcut: ""
        property int view: -1
        readonly property bool keyboardSelected: activeFocus && Config.focusVisible

        activeFocusOnTab: true
        function activate() { Engine.open(view) }
        Keys.onReturnPressed: activate()
        Keys.onEnterPressed:  activate()
        Keys.onSpacePressed:  activate()

        width: line.implicitWidth + 28
        height: 38
        radius: height / 2
        color: Config.state(Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0), Config.primary,
                            area.containsMouse, area.pressed || keyboardSelected)

        Row {
            id: line
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: link.title
                color: Config.primary
                font.family: Config.font
                font.pixelSize: Config.body + 1
                font.weight: Font.DemiBold
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                width: Math.min(implicitWidth, 240)
                text: link.detail
                elide: Text.ElideMiddle
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.body
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "chevron_right"
                size: 22
                color: Config.primary
                // nudges along under the pointer: this goes somewhere
                transform: Translate { x: area.containsMouse ? 3 : 0; Behavior on x { NumberAnimation { duration: 120 } } }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => Engine.open(link.view, link.mapToItem(null, mouse.x, mouse.y).x)
        }

        FocusRing { on: link.keyboardSelected }
        KeyBadge { key: link.shortcut; anchors { right: parent.right; top: parent.top; rightMargin: -6; topMargin: -6 } }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 12

        Header {
            width: parent.width
            title: "Theme"
            onBack: Engine.back()

            Pill { kind: "text"; icon: Config.symbol.settings; iconSize: 22; shortcut: "i"; onClicked: x => Engine.open(Engine.View.Settings, x) }
        }

        // ================= the wallpapers: one large row =================
        SectionLink {
            x: -14                                       // the title lines up with the content
            title: "Wallpaper"
            detail: Wallpaper.files.length > 0 ? Wallpaper.files.length + (Wallpaper.files.length === 1 ? " image" : " images") : ""
            shortcut: "w"
            view: Engine.View.Wallpapers
        }

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

        // ================= the colours: a footer =================
        Rectangle {
            width: parent.width
            height: 1
            color: Config.divider
        }

        Item {
            width: parent.width
            height: 40

            SectionLink {
                x: -14
                anchors.verticalCenter: parent.verticalCenter
                title: "Colours"
                detail: Config.source === "preset" ? Config.current.label
                      : Config.source === "accent" ? Config.hex(Config.accent) : "Wallpaper"
                shortcut: "c"
                view: Engine.View.Colours
            }

            Row {
                anchors { right: mode.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 8

                // every preset: its primary inside its surface
                Repeater {
                    model: Config.names

                    Swatch {
                        required property string modelData
                        readonly property var p: Config.palettes[modelData]
                        width: 30; height: 30
                        ring: p.surface
                        tone: p.primary
                        chosen: Config.source === "preset" && Config.name === modelData
                        onPicked: { Config.name = modelData; Config.source = "preset" }
                    }
                }
                // or the wallpaper's own
                Swatch {
                    width: 30; height: 30
                    tone: Wallpaper.seed
                    icon: Config.symbol.wallpaper
                    chosen: Config.source === "wallpaper"
                    onPicked: Config.source = "wallpaper"
                }
            }

            Segmented {
                id: mode
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: 96
                height: 36
                showCheck: false
                options: [{ key: "dark", icon: "dark_mode" }, { key: "light", icon: "light_mode" }]
                current: Config.dark ? "dark" : "light"
                onPicked: key => { Config.setDark(key === "dark"); Toggles.colorScheme(Config.dark) }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["← →", "pick"], ["↵", "apply"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
