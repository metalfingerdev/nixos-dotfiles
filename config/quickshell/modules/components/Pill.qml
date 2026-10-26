import QtQuick

// Shared button (Material 3). Mouse: click. Keyboard: Tab/arrows reach it (ViewLoader's default
// keys), Enter/Space press it, and its `shortcut` key (shown as a keycap while the keyboard is in
// use) presses it from anywhere in the view. `icon` (a Material Symbols name) goes before the
// text; with no text it is a round icon button.
//   kind  "tonal"     a container fill (the default)
//         "filled"    the primary colour: the one action that matters (play, connect)
//         "text"      no fill until hovered (toolbar icons, "Clear all")
//   active  the selected look of a toggle button: filled with the primary colour
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
    function press() { clicked(-1) }
    function activate() { press() }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    implicitWidth: label.text === "" && icon !== "" ? implicitHeight : content.implicitWidth + 32
    implicitHeight: 44
    radius: height / 2
    // a text button is only its state layer; the others are their fill under it
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

        Text {
            id: label
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            color: root.ink
            font.family: Config.font
            font.pixelSize: Config.body
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.clicked(area.mapToItem(null, mouse.x, mouse.y).x)
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut; anchors { right: parent.right; top: parent.top; rightMargin: -6; topMargin: -6 } }
}
