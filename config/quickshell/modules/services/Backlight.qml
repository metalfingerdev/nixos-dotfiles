pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// sysfs has no change events, so this polls.
// A drag sends many values, so only the newest one waiting runs once the previous brightnessctl call is done.
Singleton {
    id: root

    property string path: ""
    property int max: 0
    property int percent: -1     // -1 = not read yet
    readonly property bool available: path !== "" && max > 0
    readonly property string icon: percent < 34 ? "brightness_low" : percent < 67 ? "brightness_medium" : "brightness_high"

    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/backlight/*; do [ -r \"$d/brightness\" ] && echo \"$d\" && break; done"]
        stdout: StdioCollector { onStreamFinished: root.path = text.trim() }
    }

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

    Timer {
        interval: 500
        repeat: true
        running: root.path !== ""
        triggeredOnStart: true
        onTriggered: { maxFile.reload(); curFile.reload() }
    }

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
