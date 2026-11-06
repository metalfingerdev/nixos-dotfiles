import QtQuick

// Not a real spectrum (that would need cava), just a cue.
// Animates only while `running` AND actually visible: an infinite animation on a hidden item
// would keep Qt's animation driver (and the render thread) awake for nothing.
Row {
    id: root

    property bool running: false
    property int count: 3
    property int barWidth: 3
    property color color: Config.text

    spacing: 2
    height: 14

    Repeater {
        model: root.count

        Rectangle {
            id: bar
            required property int index
            property real level: 0.3

            anchors.verticalCenter: parent.verticalCenter
            width: root.barWidth
            height: Math.max(width, root.height * (root.running ? level : 0.25))
            radius: width / 2
            color: root.color

            // each bar at its own pace, so they don't move in step
            SequentialAnimation on level {
                running: root.running && root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 1.0;  duration: 280 + bar.index * 90; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.25; duration: 320 + bar.index * 70; easing.type: Easing.InOutSine }
            }
        }
    }
}
