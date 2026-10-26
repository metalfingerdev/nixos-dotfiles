import QtQuick

// A segmented button (Material 3): an outlined pill split into options; the chosen one takes the
// secondary fill and a check. options: [{ key, label, icon? }]; bind `current` to the real value
// and act in onPicked. Each segment is focusable: Tab reaches it, Enter/Space pick it.
//   Segmented { options: [{ key: "pill", label: "Pill" }, { key: "notch", label: "Notch" }]
//               current: Config.style; onPicked: k => Config.style = k }
Rectangle {
    id: root

    property var options: []
    property string current: ""
    property bool showCheck: true
    signal picked(string key)

    implicitWidth: 320
    implicitHeight: 40
    radius: height / 2
    color: "transparent"
    border.width: 1
    border.color: Config.outline
    clip: true

    Row {
        anchors.fill: parent

        Repeater {
            model: root.options

            Rectangle {
                id: segment
                required property var modelData
                required property int index
                readonly property bool chosen: modelData.key === root.current

                width: root.width / Math.max(1, root.options.length)
                height: root.height
                // the outer ends follow the pill; the inner edges stay square
                topLeftRadius: index === 0 ? root.radius : 0
                bottomLeftRadius: index === 0 ? root.radius : 0
                topRightRadius: index === root.options.length - 1 ? root.radius : 0
                bottomRightRadius: index === root.options.length - 1 ? root.radius : 0
                color: Config.state(chosen ? Config.secondary : Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0),
                                    Config.text, area.containsMouse, area.pressed || (activeFocus && Config.focusVisible))
                Behavior on color { ColorAnimation { duration: 140 } }

                activeFocusOnTab: true
                Keys.onReturnPressed: root.picked(modelData.key)
                Keys.onEnterPressed:  root.picked(modelData.key)
                Keys.onSpacePressed:  root.picked(modelData.key)

                // divider to the left of every segment but the first
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
                        size: 18
                        color: segment.chosen ? Config.secondaryInk : Config.text
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.modelData.label ?? ""
                        color: segment.chosen ? Config.secondaryInk : Config.text
                        font.family: Config.font
                        font.pixelSize: Config.body
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(segment.modelData.key)
                }
            }
        }
    }
}
