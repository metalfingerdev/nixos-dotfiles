import QtQuick

// The island's one motion (Config.curve over Config.motionMs), for a Behavior: the morph (Bar) and
// anything inside a view that has to move with the island's edge (parts/WorkspaceButtons.qml).
NumberAnimation {
    duration: Config.motionMs
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Config.curve
}
