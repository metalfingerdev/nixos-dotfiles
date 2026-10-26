import QtQuick
import QtQuick.Layouts

// A list item (Material 3): a leading icon in a tonal circle, headline, supporting text, trailing
// text, then any children (buttons, an icon). `active` marks the current one (connected, playing):
// its circle takes the primary colour and the row a tonal fill. `lead` replaces the icon with a
// component of the view's own (an app icon, album art).
// Mouse: click. Keyboard: Tab/arrows reach it, Enter/Space press it, like Pill.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property bool active: false
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    property Component lead: null
    default property alias extra: side.data
    signal clicked()

    activeFocusOnTab: true
    function press() { clicked() }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    implicitWidth: 320
    implicitHeight: subtitle !== "" ? 60 : 48
    radius: Config.innerRadius
    color: {
        const base = active ? Config.secondary : Qt.rgba(Config.container.r, Config.container.g, Config.container.b, 0)
        return keyboardSelected || area.pressed ? Config.mix(active ? base : Config.container, Config.text, 0.10)
             : area.containsMouse ? Config.mix(active ? base : Config.container, Config.text, 0.05)
             : base
    }
    border.width: keyboardSelected ? 2 : 0
    border.color: Config.primary
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
        anchors { fill: parent; leftMargin: 10; rightMargin: 12 }
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 20
            color: root.lead !== null ? "transparent" : root.active ? Config.primary : Config.high

            Loader {
                anchors.centerIn: parent
                sourceComponent: root.lead
            }

            Icon {
                anchors.centerIn: parent
                visible: root.lead === null && root.icon !== ""
                name: root.icon
                size: 20
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
}
