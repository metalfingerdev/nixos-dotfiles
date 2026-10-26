import QtQuick

// Wi-Fi strength as four rising bars. strength: 0..1.
Row {
    id: root

    property real strength: 0
    property color color: Config.text
    property int barWidth: 3

    spacing: 2
    height: 14

    Repeater {
        model: 4

        Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: root.barWidth
            height: root.height * (index + 1) / 4
            radius: 1
            // a bar lights up once the strength reaches its band (1 bar at any signal at all)
            color: root.strength > index / 4 || (index === 0 && root.strength > 0) ? root.color : Config.track
        }
    }
}
