import QtQuick
import qs.modules.components
import qs.modules.services

// At a glance, as a connected button group (Material 3): one segment per thing that is on right
// now, and nothing for what's off: a recording, the network, a Bluetooth device, Do not disturb,
// the battery. With nothing on, a single "tune" segment. The whole group is one button: clicked()
// (the views open the dashboard). Enter/Space press it from the keyboard.
Item {
    id: root

    property bool showText: true
    property real maxText: 110
    // the most the group may take: labels share what's left after the icons, and elide
    property real maxWidth: Infinity
    property real segmentHeight: 40
    property bool keyboardSelected: activeFocus && Config.focusVisible
    signal clicked(real sceneX)

    activeFocusOnTab: true
    Keys.onReturnPressed: clicked(-1)
    Keys.onEnterPressed:  clicked(-1)
    Keys.onSpacePressed:  clicked(-1)

    readonly property var items: {
        const out = []
        if (Toggles.recording)
            out.push({ icon: "radio_button_checked", text: Toggles.recordTime, tint: Config.recording })
        if (Net.current)
            out.push({ icon: Net.icon, text: Net.current.name })
        else if (Net.ethernet)
            out.push({ icon: "lan", text: "Ethernet" })
        const bt = Bluez.connected[0] ?? null
        if (bt)
            out.push({ icon: "bluetooth_connected",
                       text: bt.batteryAvailable ? Math.round(bt.battery * 100) + "%" : bt.name })
        if (Notifier.dnd)
            out.push({ icon: "do_not_disturb_on", text: "" })
        if (Energy.present)
            out.push({ icon: Energy.glyph, text: Energy.percent + "%",
                       tint: Energy.charging || Energy.full ? Config.good : Energy.level === "critical" ? Config.bad
                           : Energy.level === "low" ? Config.warn : Config.text })
        if (out.length === 0)
            out.push({ icon: "tune", text: "" })
        return out
    }
    // a label's width: maxText, or an equal share of what maxWidth leaves after icons and padding
    readonly property real textWidth: {
        const labelled = items.filter(i => i.text !== "").length
        if (labelled === 0 || !isFinite(maxWidth)) return maxText
        return Math.max(24, Math.min(maxText, (maxWidth - items.length * 52 - (items.length - 1) * 2) / labelled))
    }

    implicitWidth: row.implicitWidth
    implicitHeight: segmentHeight

    Row {
        id: row
        spacing: 2

        Repeater {
            model: root.items

            Rectangle {
                id: seg
                required property var modelData
                required property int index
                readonly property bool first: index === 0
                readonly property bool last: index === root.items.length - 1
                readonly property bool iconOnly: !root.showText || modelData.text === ""

                width: iconOnly ? root.segmentHeight + (first && last ? 0 : 4) : content.implicitWidth + 26
                height: root.segmentHeight
                // the group is one pill: round outer ends, tight inner corners
                topLeftRadius: first ? height / 2 : 6
                bottomLeftRadius: first ? height / 2 : 6
                topRightRadius: last ? height / 2 : 6
                bottomRightRadius: last ? height / 2 : 6
                color: Config.state(Config.container, Config.text, area.containsMouse, area.pressed || root.keyboardSelected)
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: seg.modelData.icon
                        size: 18
                        filled: true
                        color: seg.modelData.tint ?? Config.text
                    }
                    Text {
                        visible: !seg.iconOnly
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, root.textWidth)
                        text: seg.modelData.text
                        elide: Text.ElideRight
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.body
                        font.weight: Font.Medium
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }

    // focus ring around the whole group
    Rectangle {
        anchors { fill: row; margins: -6 }
        visible: root.keyboardSelected
        radius: height / 2
        color: "transparent"
        border.width: 3
        border.color: Config.primary
    }

    MouseArea {
        id: area
        anchors.fill: row
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(area.mapToItem(null, mouse.x, mouse.y).x)
    }
}
