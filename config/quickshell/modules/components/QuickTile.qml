import QtQuick

//   more   a round arrow inside the tile opens its view (clicked); the rest flips the setting (toggled)
//   split  Android's large tile: the icon circle flips the setting, the rest opens its view
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

    readonly property color ink: on ? Config.primaryInk : Config.text
    readonly property real inner: height - 24

    implicitWidth: 220
    implicitHeight: 72
    radius: height / 2
    color: Config.state(on ? Config.primary : Config.container, ink,
                        body.containsMouse && !arrowArea.containsMouse && !circleArea.containsMouse,
                        body.pressed || keyboardSelected)
    opacity: enabled ? 1 : 0.38
    Behavior on color { ColorAnimation { duration: 160 } }

    ClickArea {
        id: body
        onClicked: mouse => root.split ? root.clicked(body.sceneX(mouse)) : root.toggled()
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

        ClickArea {
            id: circleArea
            enabled: root.split
            onClicked: root.toggled()
        }
    }

    Column {
        anchors { left: circle.right; leftMargin: 12; verticalCenter: parent.verticalCenter
                  right: root.showSwitch ? knob.left : root.more ? arrow.left : parent.right
                  rightMargin: root.showSwitch || root.more ? 8 : 18 }
        spacing: 2

        Label {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: root.ink
            font.pixelSize: Config.body + 1
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            elide: Text.ElideRight
            color: root.on ? Config.mix(Config.primaryInk, Config.primary, 0.2) : Config.dim
            font.pixelSize: Config.small + 1
        }
    }

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

        ClickArea {
            id: arrowArea
            onClicked: mouse => root.clicked(arrowArea.sceneX(mouse))
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
    KeyBadge { key: root.shortcut; anchors.rightMargin: root.more ? root.inner + 18 : 10 }
}
