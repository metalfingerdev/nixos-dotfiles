import QtQuick

Rectangle {
    id: root

    property color tone: "grey"
    property color ring: "transparent"
    property string icon: ""
    property bool chosen: false
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    readonly property bool ringed: ring.a > 0
    signal picked()

    activeFocusOnTab: true
    function activate() { picked() }

    implicitWidth: 52
    implicitHeight: 52
    radius: width / 2
    color: ringed ? ring : tone
    border.width: 1
    border.color: Qt.rgba(Config.outline.r, Config.outline.g, Config.outline.b, 0.5)
    scale: hovered && !area.pressed ? 1.08 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    Rectangle {
        id: inner
        visible: root.ringed
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.5)
        height: width
        radius: width / 2
        color: root.tone
    }

    Icon {
        anchors.centerIn: parent
        visible: root.chosen || root.icon !== ""
        name: root.chosen ? "check" : root.icon
        size: Math.round(root.width * (root.ringed ? 0.34 : 0.48))
        color: root.tone.hslLightness > 0.6 ? "#000000" : "#ffffff"
    }

    ClickArea {
        id: area
        onClicked: root.picked()
    }

    FocusRing { on: root.keyboardSelected }
}
