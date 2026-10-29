import QtQuick
import qs.modules.parts

// The workspace-switch toast (Triggers raises it when the focused workspace changes): GNOME's
// indicator, a dot per workspace and a bar for the focused one. A capsule as tall as the clock,
// so the island only stretches sideways. The dots can be clicked.
Item {
    implicitWidth: dots.implicitWidth + 40
    implicitHeight: 36

    WorkspaceDots {
        id: dots
        anchors.centerIn: parent
        clickable: true
    }
}
