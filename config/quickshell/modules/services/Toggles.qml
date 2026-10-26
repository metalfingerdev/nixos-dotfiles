pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The quick settings that are neither Wi-Fi, Bluetooth, sound nor notifications. Knows nothing
// about the island. Each one needs a program; `has(tool)` says whether it's installed, and the
// dashboard only shows the tiles that can work.
//   caffeine     keeps the session from idling (systemd-inhibit; hypridle respects it)
//   nightLight   warm screen (hyprsunset, at `warmth` K; remembered). Stopping it restores the colours
//   recording    records the focused monitor (wf-recorder) to ~/Videos/Recordings; a notification
//                says where it went. recordSeconds counts up while it runs
//   airplane     Wi-Fi and Bluetooth off together
//   profile      power-profiles-daemon: "power-saver" | "balanced" | "performance" ("" = not running)
//   screenshot() an area, saved to ~/Pictures/Screenshots and copied (grimblast), after the island is gone
//   colorScheme(dark)  GTK/libadwaita apps' light or dark preference
Singleton {
    id: root

    // ---- which tools exist ----
    property var tools: []
    function has(tool) { return tools.includes(tool) }

    Process {
        running: true
        command: ["sh", "-c", "for t in systemd-inhibit hyprsunset wf-recorder powerprofilesctl grimblast gsettings notify-send xdg-open; "
                            + "do command -v \"$t\" >/dev/null 2>&1 && echo \"$t\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.tools = text.split("\n").filter(t => t !== "")
                root.readProfile()
            }
        }
    }

    // ---- caffeine ----
    property bool caffeine: false
    Process {
        running: root.caffeine && root.has("systemd-inhibit")
        command: ["systemd-inhibit", "--what=idle", "--who=Island", "--why=Caffeine", "--mode=block", "sleep", "infinity"]
    }

    // ---- night light ----
    property bool nightLight: false
    property int warmth: 4500
    Process {
        running: root.nightLight && root.has("hyprsunset")
        command: ["hyprsunset", "-t", String(root.warmth)]
    }

    property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini"
        category: "toggles"
        property alias nightLight: root.nightLight
        property alias warmth: root.warmth
    }

    // ---- airplane mode ----
    readonly property bool airplane: !Net.wifiEnabled && (!Bluez.available || !Bluez.enabled)
    function setAirplane(on) { Net.setWifi(!on); Bluez.setEnabled(!on) }

    // ---- screen recording ----
    readonly property bool recording: recorder.running
    property string recordFile: ""
    property int recordSeconds: 0
    readonly property string recordTime: Math.floor(recordSeconds / 60) + ":" + String(recordSeconds % 60).padStart(2, "0")

    function record(on) {
        if (on && !recorder.running && has("wf-recorder")) {
            const dir = StandardPaths.writableLocation(StandardPaths.MoviesLocation).toString().replace("file://", "") + "/Recordings"
            const output = Hyprland.focusedMonitor?.name ?? ""
            recordFile = dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4"
            recordSeconds = 0
            recorder.command = ["sh", "-c", "mkdir -p \"$1\" && shift && exec wf-recorder -y \"$@\"", "sh", dir]
                .concat(output ? ["-o", output] : []).concat(["-f", recordFile])
            recorder.running = true
        } else if (!on && recorder.running) {
            recorder.signal(2)                              // SIGINT: wf-recorder finishes the file
        }
    }
    Process {
        id: recorder
        onExited: (code, status) => {
            if (root.recordFile !== "" && root.has("notify-send"))
                Quickshell.execDetached(["notify-send", "-a", "Screen recorder", "-i", "media-record", "Recording saved", root.recordFile])
            root.recordFile = ""
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.recordSeconds++
    }

    // ---- power profiles ----
    property string profile: ""
    function readProfile() { if (has("powerprofilesctl")) profileGet.running = true }
    function setProfile(p) {
        if (!has("powerprofilesctl")) return
        profile = p
        profileSet.command = ["powerprofilesctl", "set", p]
        profileSet.running = true
    }
    Process {
        id: profileGet
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.profile = text.trim() }
    }
    Process { id: profileSet; onExited: root.readProfile() }

    // ---- one-shots ----
    function screenshot() {
        if (!has("grimblast")) return
        Quickshell.execDetached(["sh", "-c", "sleep 0.4; d=\"$HOME/Pictures/Screenshots\"; mkdir -p \"$d\"; "
                                           + "exec grimblast --notify copysave area \"$d/$(date +%s).png\""])
    }
    function colorScheme(dark) {
        if (has("gsettings"))
            Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", dark ? "prefer-dark" : "prefer-light"])
    }
    function open(path) { if (path) Quickshell.execDetached(["xdg-open", path]) }
}
