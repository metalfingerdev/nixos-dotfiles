import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The battery: level, charging state, time left, power draw and health.
// One view, two uses: pinned (`open battery`), and the toast Triggers raises when the charger is
// plugged in or out or the battery runs low. Click the toast to pin it.
Item {
    id: root

    readonly property color levelColor: Energy.charging || Energy.full ? Config.good
                                      : Energy.level === "critical" ? Config.bad
                                      : Energy.level === "low" ? Config.warn : Config.text

    readonly property string glyph: {
        if (!Energy.present) return "power"
        if (Energy.charging) return "battery_charging_full"
        if (Energy.full || Energy.percent >= 95) return "battery_full"
        if (Energy.level === "critical") return "battery_alert"
        return "battery_" + Math.max(0, Math.min(6, Math.floor(Energy.percent / 15))) + "_bar"
    }

    readonly property string status: {
        if (!Energy.present) return "No battery"
        const left = Energy.duration(Energy.minutesLeft)
        if (Energy.full && Energy.plugged) return "Fully charged"
        if (Energy.charging) return "Charging" + (left ? " · full in " + left : "")
        if (Energy.plugged) return "Plugged in · not charging"
        return "On battery" + (left ? " · " + left + " left" : "")
    }

    readonly property string details: [
        Energy.watts > 0 ? Energy.watts.toFixed(1) + " W" : "",
        Energy.fullWh > 0 ? Energy.energyWh.toFixed(1) + " / " + Energy.fullWh.toFixed(1) + " Wh" : "",
        Energy.health > 0 ? "health " + Energy.health + "%" : "",
        Energy.cycles > 0 ? Energy.cycles + " cycles" : ""
    ].filter(t => t !== "").join("  ·  ")

    implicitWidth: 360
    implicitHeight: Energy.present ? 108 : 64

    // a toast pins on click; the pinned view has the back pill instead
    MouseArea {
        anchors.fill: parent
        enabled: !Engine.pinned
        onClicked: Engine.open(Engine.View.Battery)
    }

    Item {
        anchors { fill: parent; margins: 12 }

        Icon {
            id: glyph
            anchors { left: parent.left; top: parent.top }
            width: 40
            height: 40
            name: root.glyph
            size: 34
            filled: true
            color: root.levelColor
        }

        Text {
            id: big
            anchors { left: glyph.right; leftMargin: 8; verticalCenter: glyph.verticalCenter }
            visible: Energy.present
            text: Energy.percent >= 0 ? Energy.percent + "%" : "…"
            color: Config.text
            font.family: Config.font
            font.pixelSize: 28
            font.weight: Font.DemiBold
        }

        Text {
            anchors { left: Energy.present ? big.right : glyph.right; leftMargin: 12; right: back.left; rightMargin: 8
                      verticalCenter: glyph.verticalCenter }
            text: root.status
            elide: Text.ElideRight
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        Pill {
            id: back
            anchors { right: parent.right; verticalCenter: glyph.verticalCenter }
            visible: Engine.pinned
            width: visible ? implicitWidth : 0
            text: "back"
            onClicked: Engine.back()
        }

        Progress {
            visible: Energy.present
            anchors { left: parent.left; right: parent.right; top: glyph.bottom; topMargin: 12 }
            thickness: 6
            fraction: Energy.percent / 100
            color: root.levelColor
        }

        Text {
            visible: Energy.present && text !== ""
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            text: root.details
            elide: Text.ElideRight
            color: Config.faint
            font.family: Config.font
            font.pixelSize: Config.small
        }
    }
}
