import QtQuick
import QtQuick.Layouts

// A list item (Material 3): a leading icon in a tonal circle, headline, supporting text, trailing
// text, then any children (buttons, an icon). `active` marks the current one (connected, playing):
// its circle takes the primary colour and the row a tonal fill. `lead` replaces the icon with a
// component of the view's own (an app icon, album art).
// Mouse: click. Keyboard: Tab/arrows reach it, Enter/Space press it, its `shortcut` key too.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property bool active: false
    property string shortcut: ""
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    property Component lead: null
    default property alias extra: side.data
    signal clicked()

    activeFocusOnTab: true
    function press() { clicked() }
    function activate() { press() }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    implicitWidth: 320
    implicitHeight: subtitle !== "" ? 64 : 52
    radius: Config.innerRadius + 4
    color: {
        const base = active ? Config.secondary : Qt.rgba(Config.container.r, Config.container.g, Config.container.b, 0)
        return keyboardSelected || area.pressed ? Config.mix(active ? base : Config.container, Config.text, 0.10)
             : area.containsMouse ? Config.mix(active ? base : Config.container, Config.text, 0.05)
             : base
    }
    Behavior on color { ColorAnimation { duration: 120 } }

    // under the children, so buttons in the row still get their own clicks
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 14 }
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            radius: 22
            color: root.lead !== null ? "transparent" : root.active ? Config.primary : Config.high

            Loader {
                anchors.centerIn: parent
                sourceComponent: root.lead
            }

            Icon {
                anchors.centerIn: parent
                visible: root.lead === null && root.icon !== ""
                name: root.icon
                size: 22
                filled: root.active
                color: root.active ? Config.primaryInk : Config.text
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: root.active ? Config.secondaryInk : Config.text
                font.family: Config.font
                font.pixelSize: Config.body + 1
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: root.active ? Config.mix(Config.secondaryInk, Config.secondary, 0.25) : Config.dim
                font.family: Config.font
                font.pixelSize: Config.small + 1
            }
        }

        Text {
            visible: text !== ""
            text: root.trailing
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.small + 1
        }

        RowLayout {
            id: side
            spacing: 6
        }
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut; anchors { right: parent.right; top: parent.top; rightMargin: -6; topMargin: -6 } }
}
