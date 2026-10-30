import QtQuick
import qs.modules.island
import qs.modules.components

// The island itself: its size, its shape, and whether it hides when not in use (and what stays of
// it then). Each choice applies at once; size, shape and handle are remembered (components/Config.qml).
// Colours and the wallpaper are in views/Theme.qml; the glass is Hyprland's (hypr/modules/look.lua).
// Keys: arrows/Tab move, Left/Right step the size, Enter/Space choose, T theme, Backspace back,
// Escape closes.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 440

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

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: 14

        Header {
            width: parent.width
            title: "Settings"
            subtitle: (Config.style === "notch" ? "Notch" : "Floating") + "  ·  " + Math.round(Config.scale * 100) + " %"
                    + (Engine.autoHide ? "  ·  Hides when not in use" : "")
            onBack: Engine.back()

            Pill { kind: "text"; icon: Config.symbol.theme; iconSize: 22; shortcut: "t"; onClicked: Engine.open(Engine.View.Theme) }
        }

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

        KeyHints {
            width: parent.width
            keys: [["← →", "size"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
