import QtQuick

// Placeholder equalizer bars. `running` = animate; otherwise flat.
Item {
    id: root

    property bool running: false
    property int count: 4
    property int barW: 3
    property int gap: 2
    property color color: "#f7f7f7"

    implicitWidth: count * barW + (count - 1) * gap
    implicitHeight: 14

    Repeater {
        model: root.count

        Rectangle {
            id: bar
            required property int index

            property real level: 0.3     // fake signal, 0..1

            x: index * (root.barW + root.gap)
            width: root.barW
            height: root.height * (root.running ? level : 0.15)
            anchors.verticalCenter: parent.verticalCenter
            radius: width / 2
            color: root.color

            // each bar runs at a slightly different speed so they look uncorrelated
            SequentialAnimation on level {
                running: root.running
                loops: Animation.Infinite
                NumberAnimation { to: 1.0;  duration: 280 + bar.index * 90 }
                NumberAnimation { to: 0.25; duration: 320 + bar.index * 70 }
            }
        }
    }
}