import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// At a glance, as a connected button group (Material 3): one segment per thing that is on right
// now, and nothing for what's off: a recording, the network, a Bluetooth device, Do not disturb,
// the battery. With nothing on, a single "tune" segment. Each segment is a button of its own:
// clicked(view, sceneX) with the view it stands for (the network, Bluetooth, the notifications,
// the battery). A recording and "tune" have no view of their own: they stand for the dashboard.
// Tab/arrows reach each segment, Enter/Space press it (sceneX -1: centred).
Item {
    id: root

    property bool showText: true
    property real maxText: 110
    // the most the group may take: labels share what's left after the icons, and elide
    property real maxWidth: Infinity
    property real segmentHeight: 40
    signal clicked(int view, real sceneX)

    // Which things are on, one key per segment. Only that: a label ticking (a recording's time,
    // the battery) changes the segment in place, so the one with the keyboard focus keeps it.
    readonly property var keys: {
        const out = []
        if (Toggles.recording) out.push("record")
        if (Net.current || Net.ethernet) out.push("network")
        if (Bluez.connected.length > 0) out.push("bluetooth")
        if (Notifier.dnd) out.push("dnd")
        if (Energy.present) out.push("battery")
        return out.length > 0 ? out : ["tune"]
    }

    function glyph(key) {
        switch (key) {
        case "record":    return "radio_button_checked"
        case "network":   return Net.current ? Net.icon : "lan"
        case "bluetooth": return "bluetooth_connected"
        case "dnd":       return "do_not_disturb_on"
        case "battery":   return Energy.glyph
        }
        return "tune"
    }
    function label(key) {
        switch (key) {
        case "record":    return Toggles.recordTime
        case "network":   return Net.current ? Net.current.name : "Ethernet"
        case "bluetooth": {
            const bt = Bluez.connected[0] ?? null
            return !bt ? "" : bt.batteryAvailable ? Math.round(bt.battery * 100) + "%" : bt.name
        }
        case "battery":   return Energy.percent + "%"
        }
        return ""
    }
    function tint(key) {
        if (key === "record") return Config.recording
        if (key === "battery")
            return Energy.charging || Energy.full ? Config.good : Energy.level === "critical" ? Config.bad
                 : Energy.level === "low" ? Config.warn : Config.text
        return Config.text
    }
    // the view a segment opens
    function view(key) {
        switch (key) {
        case "network":   return Engine.View.Network
        case "bluetooth": return Engine.View.Bluetooth
        case "dnd":       return Engine.View.Notifications
        case "battery":   return Engine.View.Battery
        }
        return Engine.View.Dashboard
    }

    // a label's width: maxText, or an equal share of what maxWidth leaves after icons and padding
    readonly property real textWidth: {
        const labelled = keys.filter(k => label(k) !== "").length
        if (labelled === 0 || !isFinite(maxWidth)) return maxText
        return Math.max(24, Math.min(maxText, (maxWidth - keys.length * 52 - (keys.length - 1) * 2) / labelled))
    }

    implicitWidth: row.implicitWidth
    implicitHeight: segmentHeight

    Row {
        id: row
        spacing: 2

        Repeater {
            model: root.keys

            Rectangle {
                id: seg
                required property string modelData
                required property int index
                readonly property bool first: index === 0
                readonly property bool last: index === root.keys.length - 1
                readonly property string text: root.label(modelData)
                readonly property bool iconOnly: !root.showText || text === ""
                readonly property bool ring: activeFocus && Config.focusVisible

                width: iconOnly ? root.segmentHeight + (first && last ? 0 : 4) : content.implicitWidth + 26
                height: root.segmentHeight
                // the group is one pill: round outer ends, tight inner corners
                topLeftRadius: first ? height / 2 : 6
                bottomLeftRadius: first ? height / 2 : 6
                topRightRadius: last ? height / 2 : 6
                bottomRightRadius: last ? height / 2 : 6
                color: Config.state(Config.container, Config.text, area.containsMouse, area.pressed || ring)
                Behavior on color { ColorAnimation { duration: 120 } }

                activeFocusOnTab: true
                Keys.onReturnPressed: root.clicked(root.view(modelData), -1)
                Keys.onEnterPressed:  root.clicked(root.view(modelData), -1)
                Keys.onSpacePressed:  root.clicked(root.view(modelData), -1)

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.glyph(seg.modelData)
                        size: 18
                        filled: true
                        color: root.tint(seg.modelData)
                    }
                    Text {
                        visible: !seg.iconOnly
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, root.textWidth)
                        text: seg.text
                        elide: Text.ElideRight
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.body
                        font.weight: Font.Medium
                        font.features: { "tnum": 1 }
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => root.clicked(root.view(seg.modelData), area.mapToItem(null, mouse.x, mouse.y).x)
                }

                // inside the segment: it nearly touches its neighbours
                Rectangle {
                    anchors { fill: parent; margins: 3 }
                    visible: seg.ring
                    topLeftRadius: Math.max(0, seg.topLeftRadius - 3)
                    bottomLeftRadius: Math.max(0, seg.bottomLeftRadius - 3)
                    topRightRadius: Math.max(0, seg.topRightRadius - 3)
                    bottomRightRadius: Math.max(0, seg.bottomRightRadius - 3)
                    color: "transparent"
                    border.width: 3
                    border.color: Config.primary
                }
            }
        }
    }
}
