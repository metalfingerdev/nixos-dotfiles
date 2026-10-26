import QtQuick

// A quick settings tile (Android): a pill with an icon in a circle, a label and its state.
//   on          the primary fill; off: the container fill
//   more        a round arrow button inside the tile, on the right: it opens the setting's own view
//               (clicked). The rest of the tile flips the setting (toggled)
//   split       Android's large tile instead: the icon circle flips the setting (toggled), the rest
//               of the tile opens its view (clicked)
//   showSwitch  a switch on the right instead (the big on/off tile atop Wi-Fi and Bluetooth)
// Mouse: click. Keyboard: Tab/arrows reach it; Space flips it, Enter opens its view (with `more` or
// `split`) or flips it; its `shortcut` key flips it from anywhere in the view.
//   QuickTile { icon: "wifi"; title: "Wi-Fi"; subtitle: Net.summary; on: Net.wifiEnabled; more: true
//               onToggled: Net.setWifi(!on); onClicked: Engine.open(Engine.View.Network) }
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool on: false
    property bool more: false
    property bool split: false
    property bool showSwitch: false
    property string shortcut: ""
    property bool keyboardSelected: activeFocus && Config.focusVisible
    signal toggled()
    signal clicked(real sceneX)

    function press() { if (more || split) clicked(-1); else toggled() }
    function activate() { toggled() }

    activeFocusOnTab: true
    Keys.onReturnPressed: press()
    Keys.onEnterPressed:  press()
    Keys.onSpacePressed:  toggled()

    readonly property color ink: on ? Config.primaryInk : Config.text
    readonly property real inner: height - 24          // the icon circle and the arrow button

    implicitWidth: 220
    implicitHeight: 72
    radius: height / 2
    color: Config.state(on ? Config.primary : Config.container, ink,
                        body.containsMouse && !arrowArea.containsMouse && !circleArea.containsMouse,
                        body.pressed || keyboardSelected)
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
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: root.inner
        height: width
        radius: width / 2
        color: Config.state(root.on ? Config.primaryDeep : Config.high, root.ink, circleArea.containsMouse, circleArea.pressed)
        Behavior on color { ColorAnimation { duration: 160 } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: Math.min(24, root.inner * 0.5)
            filled: root.on
            color: root.ink
        }

        // split: the circle is the switch
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
        anchors { left: circle.right; leftMargin: 12; verticalCenter: parent.verticalCenter
                  right: root.showSwitch ? knob.left : root.more ? arrow.left : parent.right
                  rightMargin: root.showSwitch || root.more ? 8 : 18 }
        spacing: 2

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

    // the way into the setting's own view: a button of its own, inside the tile
    Rectangle {
        id: arrow
        visible: root.more
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        width: root.inner
        height: width
        radius: width / 2
        color: Config.state(root.on ? Config.primaryDeep : Config.high, root.ink, arrowArea.containsMouse, arrowArea.pressed)
        Behavior on color { ColorAnimation { duration: 160 } }

        Icon {
            anchors.centerIn: parent
            name: Config.symbol.open
            size: Math.min(22, root.inner * 0.5)
            color: root.ink
        }

        MouseArea {
            id: arrowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => root.clicked(arrowArea.mapToItem(null, mouse.x, mouse.y).x)
        }
    }

    // the switch: on a primary tile its track takes the dark ink, so it still reads as "on"
    Rectangle {
        id: knob
        visible: root.showSwitch
        anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
        width: 52
        height: 32
        radius: 16
        color: root.on ? Config.primaryInk : Config.high
        border.width: root.on ? 0 : 2
        border.color: Config.outline

        Rectangle {
            width: root.on ? 24 : 16
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.on ? parent.width - width - 4 : 8
            color: root.on ? Config.primary : Config.outline
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut; anchors { right: parent.right; top: parent.top; rightMargin: root.more ? root.inner + 18 : 10; topMargin: -6 } }
}
