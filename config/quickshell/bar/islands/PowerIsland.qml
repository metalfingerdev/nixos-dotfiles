// PowerIsland.qml
// Place in: qs/bar/islands/

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services

Item {
    property int targetWidth:  420
    property int targetHeight: 260

    // ── power profile state ───────────────────────────────────────────────────

    property string currentProfile: "balanced"

    Process {
        id: profileReadProc
        command: ["sh", "-c", "powerprofilesctl get | tr -d '\\n'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: currentProfile = this.text.trim()
        }
    }

    Process {
        id: profileSetProc
        onExited: profileReadProc.running = true
    }

    function setProfile(p) {
        profileSetProc.command = ["powerprofilesctl", "set", p]
        profileSetProc.running = true
        currentProfile = p
    }

    // ── layout ────────────────────────────────────────────────────────────────

    Column {
        anchors.centerIn: parent
        spacing: 18

        // ── battery ring + label ──────────────────────────────────────────────
        Item {
            width: 96; height: 96
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2, r = 40, lw = 8
                    var startAngle = -Math.PI / 2
                    var sweep = 2 * Math.PI * (Battery.percent / 100)

                    // track
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                    ctx.strokeStyle = "#3a3540"
                    ctx.lineWidth   = lw
                    ctx.stroke()

                    // fill
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startAngle, startAngle + sweep)
                    ctx.strokeStyle = Battery.critical ? "#ff6b6b"
                                    : Battery.charging ? "#a8e6a3"
                                    : "#8a7fff"
                    ctx.lineWidth   = lw
                    ctx.lineCap     = "round"
                    ctx.stroke()
                }

                // Repaint whenever percent or state changes.
                Connections {
                    target: Battery
                    function onPercentChanged()  { parent.requestPaint() }
                    function onChargingChanged() { parent.requestPaint() }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Battery.critical ? "#ff6b6b" : Battery.charging ? "#a8e6a3" : "white"
                    font.pixelSize: 22
                    font.bold: true
                    text: Battery.percent + "%"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#888"
                    font.pixelSize: 11
                    text: Battery.charging ? "charging" : "battery"
                }
            }
        }

        // ── power profile pills ───────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Repeater {
                model: [
                    { id: "power-saver",  label: "Saver",    icon: "󱐋" },
                    { id: "balanced",     label: "Balanced",  icon: "󰾅" },
                    { id: "performance",  label: "Perf",      icon: "󰓅" }
                ]

                delegate: Rectangle {
                    readonly property bool active: currentProfile === modelData.id
                    width: 96; height: 34; radius: 6
                    color: active ? "#8a7fff" : "#3a3540"

                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { color: "white"; font.pixelSize: 14; text: modelData.icon }
                        Text { color: "white"; font.pixelSize: 12; text: modelData.label }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: setProfile(modelData.id)
                    }
                }
            }
        }

        // ── brightness slider ─────────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Text {
                color: "white"; font.pixelSize: 14; text: "󰃟"
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: brightTrack
                width: 240; height: 8; radius: 4; color: "#3a3540"
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: brightTrack.width * (Brightness.percent / 100)
                    height: parent.height; radius: 4
                    color: "#f0c060"
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed:         (m) => Brightness.set(Math.round(m.x / brightTrack.width * 100))
                    onPositionChanged: (m) => { if (pressed) Brightness.set(Math.round(m.x / brightTrack.width * 100)) }
                }
            }

            Text {
                color: "#888"; font.pixelSize: 12
                text: Brightness.percent + "%"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}