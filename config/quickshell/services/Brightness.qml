// Brightness.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // Current brightness as a 0–100 integer, kept in sync by polling.
    property int percent: 0

    // ── internal helpers ──────────────────────────────────────────────────────

    // Read current brightness on startup and after every write.
    Process {
        id: getProc
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%\\n'"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text, 10)
                if (!isNaN(v)) root.percent = v
            }
        }
    }

    // Keep the value fresh every 2 s in case another tool changes brightness.
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: getProc.running = true
    }

    // Write process – re-used for every set/increase/decrease call.
    Process {
        id: setProc
        // command is overwritten before each run
        onExited: getProc.running = true   // re-read after the write settles
    }

    // ── public API ────────────────────────────────────────────────────────────

    function set(v: int): void {
        const clamped = Math.max(1, Math.min(100, v))
        setProc.command = ["brightnessctl", "set", clamped + "%"]
        setProc.running = true
        BarState.showBarView("brightness")
    }

    function increase(step: int): void { set(percent + (step > 0 ? step : 5)) }
    function decrease(step: int): void { set(percent - (step > 0 ? step : 5)) }

    // ── IPC ───────────────────────────────────────────────────────────────────

    IpcHandler {
        target: "brightness"

        // qs ipc call brightness get
        function get(): int { return root.percent }
        // qs ipc call brightness set 60
        function set(v: int): void { root.set(v) }
        // qs ipc call brightness increase 10
        function increase(step: int): void { root.increase(step) }
        // qs ipc call brightness decrease 10
        function decrease(step: int): void { root.decrease(step) }
    }
}
