import QtQuick
import QtQuick.Layouts

// Components don't know the Engine: wire onBack yourself.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool showBack: true
    default property alias actions: tools.data
    signal back()

    implicitHeight: 52

    RowLayout {
        anchors.fill: parent
        spacing: 10

        BackButton {
            visible: root.showBack
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.back()
        }

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 22
            color: Config.dim
            Layout.preferredWidth: 24
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Label {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                font.pixelSize: Config.title
                font.weight: Font.Normal
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
        }

        RowLayout {
            id: tools
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }
    }
}
