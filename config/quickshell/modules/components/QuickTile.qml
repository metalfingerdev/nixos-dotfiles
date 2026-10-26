import QtQuick

// A quick settings tile (Android): a pill with an icon in a circle, a label and its state.
//   on      the primary fill; off: the container fill
//   split   the circle and the rest act apart: the circle flips the setting (toggled), the rest
//           opens its details (clicked). Not split: the whole tile flips it (toggled).
//   more    shows a chevron (the tile opens a view)
// Mouse: click. Keyboard: Tab/arrows reach it, Enter/Space act as a click on the body.
//   QuickTile { icon: "wifi"; title: "Wi-Fi"; subtitle: Net.summary; on: Net.wifiEnabled; split: true
//               onToggled: Net.setWifi(!on); onClicked: Engine.open(Engine.View.Network) }
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool on: false
    property bool split: false
    property bool more: false
    property bool keyboardSelected: activeFocus && Config.focusVisible
    signal toggled()
    signal clicked(real sceneX)

    function press() { if (split) clicked(-1); else toggled() }

    activeFocusOnTab: true
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  press()

    readonly property color ink: on ? Config.primaryInk : Config.text

    implicitWidth: 180
    implicitHeight: 64
    radius: height / 2
    color: Config.state(on ? Config.primary : Config.container, ink, body.containsMouse && !circleArea.containsMouse,
                        body.pressed || keyboardSelected)
    border.width: keyboardSelected ? 2 : 0
    border.color: on ? Config.primaryInk : Config.primary
    opacity: enabled ? 1 : 0.38
    Behavior on color { ColorAnimation { duration: 160 } }

    MouseArea {
        id: body
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.split ? root.clicked(body.mapToItem(null, mouse.x, mouse.y).x) : root.toggled()
    }

    Rectangle {
        id: circle
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: root.height - 20
        height: width
        radius: width / 2
        color: Config.state(root.on ? Config.primaryDeep : Config.high, root.ink, circleArea.containsMouse, circleArea.pressed)
        Behavior on color { ColorAnimation { duration: 160 } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 20
            filled: root.on
            color: root.ink
        }

        MouseArea {
            id: circleArea
            anchors.fill: parent
            enabled: root.split
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }

    Column {
        anchors { left: circle.right; leftMargin: 10; right: chevron.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: root.ink
            font.family: Config.font
            font.pixelSize: Config.body + 1
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            elide: Text.ElideRight
            color: root.on ? Config.mix(Config.primaryInk, Config.primary, 0.2) : Config.dim
            font.family: Config.font
            font.pixelSize: Config.small + 1
        }
    }

    Icon {
        id: chevron
        anchors { right: parent.right; rightMargin: root.more ? 14 : 0; verticalCenter: parent.verticalCenter }
        width: root.more ? implicitWidth : 0
        visible: root.more
        name: "chevron_right"
        size: 20
        color: root.ink
    }
}
