import QtQuick

// A thin level bar (media position, battery). fraction: 0..1. With `seekable`, a click reports
// where (seek(fraction)); the owner decides what that means.
Item {
    id: root

    property real fraction: 0
    property color color: Theme.text
    property bool seekable: false
    property bool animated: true
    signal seek(real fraction)

    implicitWidth: 200
    implicitHeight: 4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.track

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.fraction))
            height: parent.height
            radius: parent.radius
            color: root.color
            Behavior on width { enabled: root.animated; NumberAnimation { duration: 200 } }
        }
    }

    MouseArea {
        anchors { fill: parent; topMargin: -6; bottomMargin: -6 }   // a 4px bar is hard to hit
        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.seek(Math.max(0, Math.min(1, mouse.x / root.width)))
    }
}
