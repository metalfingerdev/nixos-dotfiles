import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The battery: level, charging state, time left, and the details (power draw, capacity, health,
// cycles) as chips.
// One view, two uses: pinned (`open battery`), and the toast Triggers raises when the charger is
// plugged in or out or the battery runs low. Click the toast to pin it.
// Pinned, below them: the screen's brightness (with a backlight) and the power profile (with
// power-profiles-daemon).
// Keys (pinned): arrows/Tab move, [ ] brightness, Backspace back, Escape closes.
Item {
    id: root

    Component.onCompleted: Toggles.readProfile()

    // brightness from anywhere in the view
    Keys.onPressed: event => {
        const t = event.text
        if (t === "]") Backlight.set(Backlight.percent + 5)
        else if (t === "[") Backlight.set(Backlight.percent - 5)
        else { event.accepted = false; return }
        Engine.key()
    }

    readonly property color levelColor: Energy.charging || Energy.full ? Config.good
                                      : Energy.level === "critical" ? Config.bad
                                      : Energy.level === "low" ? Config.warn : Config.primary

    readonly property string status: {
        if (!Energy.present) return "No battery"
        const left = Energy.duration(Energy.minutesLeft)
        if (Energy.full && Energy.plugged) return "Fully charged"
        if (Energy.charging) return "Charging" + (left ? "  ·  full in " + left : "")
        if (Energy.plugged) return "Plugged in, not charging"
        return "On battery" + (left ? "  ·  " + left + " left" : "")
    }

    readonly property var details: [
        Energy.watts > 0 ? { icon: "bolt", text: Energy.watts.toFixed(1) + " W" } : null,
        Energy.fullWh > 0 ? { icon: "battery_full", text: Energy.energyWh.toFixed(1) + " / " + Energy.fullWh.toFixed(1) + " Wh" } : null,
        Energy.health > 0 ? { icon: "favorite", text: "Health " + Energy.health + "%" } : null,
        Energy.cycles > 0 ? { icon: "autorenew", text: Energy.cycles + " cycles" } : null
    ].filter(d => d !== null)

    implicitWidth: 600
    implicitHeight: column.implicitHeight + 48

    // a toast pins on click; the pinned view has the back arrow instead
    MouseArea {
        anchors.fill: parent
        enabled: !Engine.pinned
        onClicked: Engine.open(Engine.View.Battery)
    }

    Column {
        id: column
        x: 24; y: 24
        width: parent.width - 48
        spacing: 18

        Header {
            visible: Engine.pinned
            width: parent.width
            title: "Battery"
            subtitle: root.status
            onBack: Engine.back()
        }

        Item {
            width: parent.width
            height: 76

            Rectangle {
                id: badge
                anchors.verticalCenter: parent.verticalCenter
                width: 76; height: 76; radius: 38
                color: Config.mix(Config.container, root.levelColor, 0.22)

                Icon {
                    anchors.centerIn: parent
                    name: Energy.glyph
                    size: 38
                    filled: true
                    color: root.levelColor
                }
            }
            Column {
                anchors { left: badge.right; leftMargin: 14; right: parent.right; verticalCenter: parent.verticalCenter }

                Text {
                    text: Energy.present ? (Energy.percent >= 0 ? Energy.percent + "%" : "…") : "No battery"
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.display
                    font.weight: Font.Normal
                    font.features: { "tnum": 1 }
                }
                Text {
                    visible: !Engine.pinned
                    width: parent.width
                    text: root.status
                    elide: Text.ElideRight
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
            }
        }

        // a thick Material progress bar
        Progress {
            visible: Energy.present
            width: parent.width
            thickness: 16
            fraction: Energy.percent / 100
            color: root.levelColor
        }

        Flow {
            visible: Energy.present && root.details.length > 0
            width: parent.width
            spacing: 6

            Repeater {
                model: root.details

                Rectangle {
                    required property var modelData
                    width: chip.implicitWidth + 28
                    height: 40
                    radius: 20
                    color: Config.container

                    Row {
                        id: chip
                        anchors.centerIn: parent
                        spacing: 6
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 16; color: Config.dim }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            color: Config.text
                            font.family: Config.font
                            font.pixelSize: Config.small + 1
                        }
                    }
                }
            }
        }

        Slider {
            visible: Engine.pinned && Backlight.available
            width: parent.width
            implicitHeight: 48
            icon: Backlight.percent < 34 ? "brightness_low" : Backlight.percent < 67 ? "brightness_medium" : "brightness_high"
            value: Backlight.percent / 100
            onMoved: v => Backlight.set(v * 100)
        }

        Segmented {
            visible: Engine.pinned && Toggles.profile !== ""
            width: parent.width
            options: [
                { key: "power-saver", label: "Saver",       icon: "eco" },
                { key: "balanced",    label: "Balanced",    icon: "balance" },
                { key: "performance", label: "Performance", icon: "speed" }
            ]
            current: Toggles.profile
            onPicked: key => Toggles.setProfile(key)
        }
    }
}
