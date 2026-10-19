import QtQuick

// Tiny shared button so views can prove clicks inside the island work.
// `active: false` dims it and ignores the click, but still swallows the mouse event
// (unlike `enabled: false`, which lets the click fall through to the island's close handler).
// Size it per view with implicitHeight / fontSize / hPad; defaults are the original compact look.
Rectangle {
    id: root

    property alias text: label.text
    property alias fontSize: label.font.pixelSize
    property int hPad: 24
    property bool keyboardSelected: false
    property bool pointerTracking: false
    property bool active: true
    signal clicked

    implicitWidth: label.implicitWidth + hPad
    implicitHeight: 28
    radius: height / 2
    opacity: active ? 1.0 : 0.35
    color: (active && (keyboardSelected || area.containsMouse)) ? "#2e2e2e" : "#1a1a1a"

    Text {
        id: label
        anchors.centerIn: parent
        color: "#f7f7f7"
        font.pixelSize: 13
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouse => {
            if (!root.active) return
            // capture BEFORE emitting clicked(): the handler usually opens a view, and the
            // island must already know where to go when that transition starts
            if (root.pointerTracking) {
                const p = area.mapToItem(null, mouse.x, mouse.y)
                IslandState.setPointer(p.x)
            }
            root.clicked()
        }
    }
}