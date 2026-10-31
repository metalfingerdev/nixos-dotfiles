import QtQuick

Rectangle {
    id: root

    property var options: []
    property string current: ""
    property bool showCheck: true
    signal picked(string key)

    implicitWidth: 320
    implicitHeight: 48
    radius: height / 2
    color: "transparent"
    border.width: 1
    border.color: Config.outline

    Row {
        anchors.fill: parent

        Repeater {
            model: root.options

            Rectangle {
                id: segment
                required property var modelData
                required property int index
                readonly property bool chosen: modelData.key === root.current
                readonly property string shortcut: modelData.shortcut ?? ""
                readonly property bool ring: activeFocus && Config.focusVisible

                function activate() { root.picked(modelData.key) }

                width: root.width / Math.max(1, root.options.length)
                height: root.height
                topLeftRadius: index === 0 ? root.radius : 0
                bottomLeftRadius: index === 0 ? root.radius : 0
                topRightRadius: index === root.options.length - 1 ? root.radius : 0
                bottomRightRadius: index === root.options.length - 1 ? root.radius : 0
                color: Config.state(chosen ? Config.secondary : Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0),
                                    Config.text, area.containsMouse, area.pressed || ring)
                Behavior on color { ColorAnimation { duration: 140 } }

                activeFocusOnTab: true

                Rectangle {
                    visible: segment.index > 0
                    width: 1
                    height: parent.height
                    color: Config.outline
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        readonly property string glyph: segment.chosen && root.showCheck ? "check" : segment.modelData.icon ?? ""
                        visible: glyph !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        name: glyph
                        size: 20
                        color: segment.chosen ? Config.secondaryInk : Config.text
                    }
                    Label {
                        visible: text !== ""                 // an icon-only option stays centred
                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.modelData.label ?? ""
                        color: segment.chosen ? Config.secondaryInk : Config.text
                        font.weight: Font.Medium
                    }
                }

                ClickArea {
                    id: area
                    onClicked: segment.activate()
                }

                // inside the segment: it touches its neighbours
                Rectangle {
                    anchors { fill: parent; margins: 4 }
                    visible: segment.ring
                    topLeftRadius: Math.max(0, segment.topLeftRadius - 4)
                    bottomLeftRadius: Math.max(0, segment.bottomLeftRadius - 4)
                    topRightRadius: Math.max(0, segment.topRightRadius - 4)
                    bottomRightRadius: Math.max(0, segment.bottomRightRadius - 4)
                    color: "transparent"
                    border.width: 3
                    border.color: Config.primary
                }
                KeyBadge { key: segment.shortcut; anchors { rightMargin: 8; topMargin: -8 } }
            }
        }
    }
}
