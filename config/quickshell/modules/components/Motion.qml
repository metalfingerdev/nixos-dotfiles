import QtQuick

// Whatever moves with the island's edge needs the morph's own motion, or the two drift apart.
NumberAnimation {
    duration: Config.motionMs
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Config.curve
}
