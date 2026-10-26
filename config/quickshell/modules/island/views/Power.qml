import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Lock, suspend, log out, restart, shut down. The last three ask first: the first press arms the
// tile (it turns red and says "again?"), a second press within `confirmMs` runs it.
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

    implicitWidth: tiles.implicitWidth + 24
    implicitHeight: column.implicitHeight + 24

    Column {
        id: column
        x: 12; y: 12
        width: parent.width - 24
        spacing: 10

        Header {
            width: parent.width
            icon: "power_settings_new"
            title: "Power"
            subtitle: Session.uptimeText
            onBack: Engine.back()
        }

        Row {
            id: tiles
            spacing: 8

            Repeater {
                model: Session.actions

                Tile {
                    id: tile
                    required property var modelData
                    readonly property bool waiting: root.armed === modelData.id

                    width: 76
                    height: 76
                    tint: waiting ? Config.bad : "transparent"
                    onClicked: root.press(modelData)

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: tile.modelData.icon
                            size: 26
                            color: tile.waiting ? Config.surface : Config.text
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.waiting ? "again?" : tile.modelData.label
                            color: tile.waiting ? Config.surface : Config.text
                            font.family: Config.font
                            font.pixelSize: Config.small
                            font.weight: tile.waiting ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
