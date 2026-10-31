import QtQuick

// kind: "tonal" | "filled" (the one action that matters) | "text" (no fill until hovered)
Rectangle {
    id: root

    property alias text: label.text
    property string icon: ""
    property string kind: "tonal"
    property bool active: false
    property real iconSize: 20
    property string shortcut: ""
    // highlighted for keyboard navigation. Default: it has focus (and the keyboard is in use). A
    // view that keeps focus elsewhere (the launcher's search field) binds it to its own selection.
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    // sceneX: where the mouse clicked. -1 from the keyboard: there's no pointer to anchor to, so a
    // view opened with it (Engine.open(v, x)) is centred, the same as one opened over IPC.
    signal clicked(real sceneX)

    readonly property bool filled: active || kind === "filled"
    readonly property bool bare: kind === "text" && !filled
    readonly property color ink: filled ? Config.primaryInk : bare && label.text !== "" ? Config.primary : Config.text

    activeFocusOnTab: true
    function activate() { clicked(-1) }

    implicitWidth: label.text === "" && icon !== "" ? implicitHeight : content.implicitWidth + 32
    implicitHeight: 44
    radius: height / 2
    color: bare ? Qt.rgba(ink.r, ink.g, ink.b, area.pressed ? 0.14 : area.containsMouse || keyboardSelected ? 0.10 : 0)
                : Config.state(filled ? Config.primary : Config.container, ink, area.containsMouse || keyboardSelected, area.pressed)
    opacity: enabled ? 1 : 0.38
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: root.iconSize
            filled: root.filled
            color: root.ink
        }

        Label {
            id: label
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            color: root.ink
            font.weight: Font.Medium
        }
    }

    ClickArea {
        id: area
        onClicked: mouse => root.clicked(area.sceneX(mouse))
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut }
}
