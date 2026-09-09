// Battery.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── public properties ─────────────────────────────────────────────────────

    // 0–100 integer percentage reported by upower.
    property int     percent:   0
    // True while the adapter is plugged in (Charging or Fully-charged state).
    property bool    charging:  false
    // True when the battery level is critically low (≤ 15 %).
    readonly property bool critical: percent <= 15 && !charging

    // ── internal polling ──────────────────────────────────────────────────────

    // One upower call returns e.g.:
    //   percentage:          72%
    //   state:               discharging
    // We grab both values with a tiny awk script and emit "72 discharging".
    Process {
        id: upowerProc
        command: [
            "sh", "-c",
            "upower -i $(upower -e | grep BAT | head -1) " +
            "| awk '/percentage/{p=$2} /state/{s=$2} END{printf \"%s %s\", p, s}'"
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(" ")
                if (parts.length >= 2) {
                    const pct   = parseInt(parts[0], 10)
                    const state = parts[1]
                    if (!isNaN(pct)) root.percent  = pct
                    root.charging = (state === "charging" || state === "fully-charged")
                }
            }
        }
    }

    // Poll every 30 s – battery level changes slowly.
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: upowerProc.running = true
    }

    // Flash the bar whenever the charging state flips (plug / unplug).
    onChargingChanged: BarState.showBarView("power")

    // Flash the bar when we cross into critical territory.
    onCriticalChanged: {
        if (critical) BarState.showBarView("power")
    }

    // ── IPC ───────────────────────────────────────────────────────────────────

    IpcHandler {
        target: "power"

        // qs ipc call power get
        function get(): int    { return root.percent  }
        // qs ipc call power charging
        function charging(): bool { return root.charging }
        // qs ipc call power critical
        function critical(): bool { return root.critical }
    }
}
