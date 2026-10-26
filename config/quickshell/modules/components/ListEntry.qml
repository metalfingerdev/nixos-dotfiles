import QtQuick
import QtQuick.Layouts

// A clickable row for lists (networks, devices, players): icon, title, subtitle, trailing text,
// then any children (pills, an icon). `active` marks the current one (connected, playing).
// `lead` replaces the icon with a component of the view's own (SignalBars, an app icon).
// Mouse: click. Keyboard: Tab/arrows reach it, Enter/Space press it, like Pill.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property bool active: false
    property bool keyboardSelected: activeFocus
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
    implicitHeight: subtitle !== "" ? 46 : 36
    radius: Config.innerRadius
    color: keyboardSelected ? Config.selected : area.containsMouse ? Config.hover : "transparent"
    border.width: keyboardSelected ? 1 : 0
    border.color: Config.faint

    // under the children, so pills in the row still get their own clicks
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 10

        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

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
                color: root.active ? Config.accent : Config.text
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: root.active ? Config.accent : Config.text
                font.family: Config.font
                font.pixelSize: Config.body
                font.weight: root.active ? Font.DemiBold : Font.Normal
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.small
            }
        }

        Text {
            visible: text !== ""
            text: root.trailing
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.small
        }

        RowLayout {
            id: side
            spacing: 6
        }
    }
}
