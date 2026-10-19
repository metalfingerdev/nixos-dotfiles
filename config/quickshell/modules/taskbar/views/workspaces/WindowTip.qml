import QtQuick
import qs.modules.services

// One shared tooltip for every window preview. Lives in the top layer of the view and is clamped to it,
// because the island body clips everything that sticks out (a Popup would not fare better in a layer-shell surface).
Rectangle {
    id: root

    property Item anchorItem: null
    property string text: ""
    readonly property bool shown: anchorItem !== null && text.length > 0

    readonly property int gap: 6

    implicitWidth: label.implicitWidth + 20
    implicitHeight: label.implicitHeight + 10
    width: implicitWidth
    height: implicitHeight
    radius: 7
    color: OverviewConfig.colors.tooltip
    opacity: shown && showDelay.ready ? 1 : 0
    visible: opacity > 0
    enabled: false              // never steals hover from the window underneath

    Behavior on opacity { NumberAnimation { duration: OverviewConfig.moveFastMs; easing.type: Easing.OutCubic } }

    function show(item, message) {
        text = message
        anchorItem = item
        showDelay.ready = false
        showDelay.restart()
        Qt.callLater(place)
    }

    function hide(item) {
        if (!item || anchorItem === item) {
            anchorItem = null
            showDelay.stop()
            showDelay.ready = false
        }
    }

    function place() {
        if (!anchorItem || !parent) return
        const p = anchorItem.mapToItem(parent, 0, 0)
        const below = p.y + anchorItem.height + gap
        const above = p.y - height - gap
        const ny = below + height <= parent.height ? below : above
        x = Math.max(4, Math.min(parent.width - width - 4, p.x + (anchorItem.width - width) / 2))
        y = Math.max(4, Math.min(parent.height - height - 4, ny))
    }

    onWidthChanged: Qt.callLater(place)
    onHeightChanged: Qt.callLater(place)

    Timer {
        id: showDelay
        property bool ready: false
        interval: 350
        onTriggered: ready = true
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: OverviewConfig.colors.tooltipText
        font.pixelSize: 12
        wrapMode: Text.Wrap
        width: Math.min(implicitWidth, 320)
    }
}