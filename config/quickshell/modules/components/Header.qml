import QtQuick
import QtQuick.Layouts

// A view's title row: icon, title and subtitle on the left; the view's own controls (children of
// Header) on the right, then "back". Header doesn't know the Engine: wire onBack yourself.
//   Header { icon: "wifi"; title: "Wi-Fi"; onBack: Engine.back(); Toggle { ... } }
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool showBack: true
    default property alias actions: tools.data
    signal back()

    implicitHeight: 40

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 22
            Layout.preferredWidth: 26
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.large
                font.weight: Font.DemiBold
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

        RowLayout {
            id: tools
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }

        Pill {
            visible: root.showBack
            Layout.alignment: Qt.AlignVCenter
            text: "back"
            onClicked: root.back()
        }
    }
}
