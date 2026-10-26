import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Lock, suspend, log out, restart, shut down. The last three ask first: the first press arms the
// tile (it turns red and says "again?"), a second press within `confirmMs` runs it.
// Keys: L S O R P (each tile shows its own), arrows/Tab move, Enter presses, Escape back.
Item {
    id: root

    readonly property int confirmMs: 3000
    property string armed: ""

    function press(a) {
        if (a.confirm && armed !== a.id) { armed = a.id; disarm.restart(); return }
        armed = ""
        Engine.close()                       // gone before the screen locks or the session ends
        Session.run(a.id)
    }

    Timer { id: disarm; interval: root.confirmMs; onTriggered: root.armed = "" }
    Component.onCompleted: Session.refresh()

    implicitWidth: tiles.implicitWidth + 48
    implicitHeight: column.implicitHeight + 48

    Column {
        id: column
        x: 24; y: 24
        width: parent.width - 48
        spacing: 18

        Header {
            width: parent.width
            title: "Power"
            subtitle: Session.uptimeText
            onBack: Engine.back()
        }

        Row {
            id: tiles
            spacing: 12

            Repeater {
                model: Session.actions

                Tile {
                    id: tile
                    required property var modelData
                    readonly property bool waiting: root.armed === modelData.id

                    width: 128
                    height: 128
                    radius: Config.cardRadius + 4
                    shortcut: modelData.key
                    tint: waiting ? Config.bad : "transparent"
                    onClicked: root.press(modelData)

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 56; height: 56; radius: 28
                            color: tile.waiting ? Qt.rgba(0, 0, 0, 0.15) : Config.high

                            Icon {
                                anchors.centerIn: parent
                                name: tile.modelData.icon
                                size: 28
                                color: tile.waiting ? Config.surface : Config.text
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.waiting ? "Again?" : tile.modelData.label
                            color: tile.waiting ? Config.surface : Config.text
                            font.family: Config.font
                            font.pixelSize: Config.body
                            font.weight: tile.waiting ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
