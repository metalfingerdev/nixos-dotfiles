import QtQuick
import QtQuick.Layouts

// A view's top app bar (Material 3): a back arrow, then the title and a supporting line, then the
// view's own controls (children of Header) on the right. Header doesn't know the Engine: wire
// onBack yourself.
//   Header { title: "Internet"; subtitle: Net.summary; onBack: Engine.back(); Toggle { ... } }
Item {
    id: root

    property string icon: ""            // optional, shown after the arrow (most views leave it out)
    property string title: ""
    property string subtitle: ""
    property bool showBack: true
    default property alias actions: tools.data
    signal back()

    implicitHeight: 52

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Pill {
            visible: root.showBack
            Layout.alignment: Qt.AlignVCenter
            kind: "text"
            icon: "arrow_back"
            iconSize: 24
            implicitHeight: 48
            activeFocusOnTab: false             // Escape/Backspace go back; Tab starts on the view itself
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

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.title
                font.weight: Font.Normal
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Config.dim
                font.family: Config.font
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
