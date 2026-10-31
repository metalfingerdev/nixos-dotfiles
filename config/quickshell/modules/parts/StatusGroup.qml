import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// At a glance, as a connected button group (Material 3) on a pill of its own: one segment per thing
// that is on right now, and nothing for what's off: a recording, the network, a Bluetooth device,
// Do not disturb, the battery. Each segment is a button: clicked(view, sceneX) with the view it
// stands for (the network, Bluetooth, the notifications, the battery; a recording has none of its
// own, so the dashboard). The group itself stands for the dashboard: its pill, anywhere that isn't a
// segment, and the "tune" button at its start, which is the part big enough to aim for and the part
// the keyboard can reach. Tab/arrows reach each button, Enter/Space press it (sceneX -1: centred).
Rectangle {
    id: root

    readonly property int pad: 4
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
        return out
    }

    function glyph(key) {
        switch (key) {
        case "record":    return "radio_button_checked"
        case "network":   return Net.current ? Net.icon : "lan"
        case "bluetooth": return "bluetooth_connected"
        case "dnd":       return "do_not_disturb_on"
        case "battery":   return Energy.glyph
        }
        return ""
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

    // the most a label may take: maxText, or if maxWidth is too tight for that, what's left after the
    // "tune" button, the icons, the padding and the labels short enough to fit whole ("100%" stays
    // whole; only a long name elides)
    FontMetrics {
        id: metrics
        font.family: Config.font
        font.pixelSize: Config.body
        font.weight: Font.Medium
    }
    readonly property real textWidth: {
        if (!isFinite(maxWidth)) return maxText
        const widths = keys.map(k => Math.ceil(metrics.advanceWidth(label(k)))).filter(w => w > 0).sort((a, b) => a - b)
        let left = maxWidth - (2 * pad + segmentHeight + keys.length * (50 + 2))
        for (let i = 0; i < widths.length; i++) {
            const share = left / (widths.length - i)
            if (widths[i] > share) return Math.max(24, Math.min(maxText, share))
            left -= widths[i]
        }
        return maxText
    }

    implicitWidth: row.implicitWidth + 2 * pad
    implicitHeight: segmentHeight + 2 * pad
    radius: height / 2
    color: Config.state(Config.container, Config.text, back.containsMouse, back.pressed)
    Behavior on color { ColorAnimation { duration: 120 } }

    // the group's own pill: under the buttons, so it only sees what misses them
    MouseArea {
        id: back
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(Engine.View.Dashboard, back.mapToItem(null, mouse.x, mouse.y).x)
    }

    Row {
        id: row
        x: root.pad
        y: root.pad
        spacing: 2

        Pill {
            implicitHeight: root.segmentHeight
            kind: "text"
            icon: Config.symbol.dashboard
            onClicked: x => root.clicked(Engine.View.Dashboard, x)
        }

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
                color: Config.state(Config.high, Config.text, area.containsMouse, area.pressed || ring)
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
