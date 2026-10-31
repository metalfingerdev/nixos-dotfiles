import QtQuick

MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    // what Engine.open(view, x) anchors a view on
    function sceneX(mouse) { return mapToItem(null, mouse.x, mouse.y).x }
}
