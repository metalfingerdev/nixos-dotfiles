pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Knows /sys/class/backlight. Knows nothing about the island.
// sysfs has no change events, so we poll (same approach as DynamicGlacier).
// On a desktop with no backlight, `path` stays "" and nothing ever fires.
// set(percent) goes through brightnessctl (the keys use it too); a drag sends many values, so
// only the newest one waiting runs once the previous call is done.
Singleton {
    id: root

    property string path: ""     // e.g. /sys/class/backlight/intel_backlight
    property int max: 0
    property int percent: -1     // -1 = not read yet
    readonly property bool available: path !== "" && max > 0

    // 1. Find the backlight device once.
    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/backlight/*; do [ -r \"$d/brightness\" ] && echo \"$d\" && break; done"]
        stdout: StdioCollector { onStreamFinished: root.path = text.trim() }
    }

    // 2. Read max + current from files.
    FileView {
        id: maxFile
        path: root.path === "" ? "" : root.path + "/max_brightness"
        printErrors: false
        onLoaded: root.max = parseInt(text())
    }

    FileView {
        id: curFile
        path: root.path === "" ? "" : root.path + "/brightness"
        printErrors: false
        onLoaded: {
            if (root.max > 0)
                root.percent = Math.round(parseInt(text()) * 100 / root.max)
        }
    }

    // 3. Re-read twice a second. percent only emits when the rounded value changes.
    Timer {
        interval: 500
        repeat: true
        running: root.path !== ""
        triggeredOnStart: true
        onTriggered: { maxFile.reload(); curFile.reload() }
    }

    // ---- setting it ----
    property int wanted: -1
    function set(p) {
        if (!available) return
        wanted = Math.max(1, Math.min(100, Math.round(p)))     // never fully dark from a slider
        percent = wanted                                       // show it at once; the poll confirms
        if (!setter.running) flush()
    }
    function flush() {
        if (wanted < 0) return
        setter.command = ["brightnessctl", "-q", "-d", path.split("/").pop(), "set", wanted + "%"]
        wanted = -1
        setter.running = true
    }
    Process {
        id: setter
        onExited: root.flush()
    }
}
