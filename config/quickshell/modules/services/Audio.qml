pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Knows PipeWire. Knows nothing about the island.
// Exposes plain values; consumers react to volumeChanged / mutedChanged.
//   sink     the default output: volume, muted (setVolume, toggleMute)
//   source   the default microphone: micVolume, micMuted (toggleMic)
//   sinks    every output device, for picking where sound goes (setSink)
//   streams  every app playing sound right now (the mixer)
// Any one of them: level / isMuted / setLevel / toggleMuted take the node.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property int  volume: level(sink)
    readonly property bool muted:  isMuted(sink)
    readonly property bool hasMic: source !== null
    readonly property int  micVolume: level(source)
    readonly property bool micMuted: isMuted(source)

    // hardware outputs only: not the apps' streams
    readonly property var sinks: Array.from(Pipewire.nodes.values).filter(n => n.isSink && !n.isStream && n.audio)
    // apps' playback streams. To PipeWire a playback stream is a sink as well (sound goes into it),
    // so isSink is true for these too; a recording (a mic stream) isn't one
    readonly property var streams: Array.from(Pipewire.nodes.values).filter(n => n.isSink && n.isStream && n.audio)

    // ---- any node: an output, the microphone, an app ----
    function level(node)   { return Math.round((node?.audio?.volume ?? 0) * 100) }
    function isMuted(node) { return node?.audio?.muted ?? false }
    // percent, 0..100; setting a level unmutes
    function setLevel(node, percent) {
        if (!node?.audio) return
        node.audio.muted = false
        node.audio.volume = Math.max(0, Math.min(100, percent)) / 100
    }
    function toggleMuted(node) { if (node?.audio) node.audio.muted = !node.audio.muted }

    // ---- the defaults ----
    function setVolume(percent) { setLevel(sink, percent) }
    function toggleMute() { toggleMuted(sink) }
    function toggleMic()  { toggleMuted(source) }
    function setSink(node) { if (node) Pipewire.preferredDefaultAudioSink = node }
    // the next output in the list, wrapping
    function nextSink() {
        if (sinks.length < 2) return
        setSink(sinks[(sinks.indexOf(sink) + 1) % sinks.length])
    }
    // a short name for an output: its description without the card's long prefix
    function label(node) { return node ? (node.nickname || node.description || node.name || "Output") : "No output" }
    // headphones, a speaker, HDMI, Bluetooth
    function glyph(node) {
        const n = ((node?.name ?? "") + " " + (node?.description ?? "")).toLowerCase()
        if (n.includes("bluez") || n.includes("headset") || n.includes("headphone")) return "headphones"
        if (n.includes("hdmi") || n.includes("displayport")) return "tv"
        return "speaker"
    }

    // ---- an app's stream ----
    function appName(node) {
        const p = node?.properties ?? {}
        return p["application.name"] || node?.description || node?.name || "App"
    }
    // what it plays: a tab's title, a track ("" when it says nothing more than the app's name)
    function mediaName(node) {
        const m = node?.properties?.["media.name"] ?? ""
        return m === appName(node) ? "" : m
    }
    // its icon from the theme ("" if there is none): the stream's own, else its app's desktop entry
    function appIcon(node) {
        const p = node?.properties ?? {}
        if (p["application.icon-name"]) return Quickshell.iconPath(p["application.icon-name"], true)
        const app = String(p["application.process.binary"] || p["application.name"] || "")
        if (app === "") return ""
        DesktopEntries.applications.values          // re-run when the entry index updates
        const entry = DesktopEntries.heuristicLookup(app)
        return Quickshell.iconPath(entry?.icon || app.toLowerCase(), true)
    }

    // Without this, a node's audio stays unbound (no volume): PipeWire objects must be "tracked".
    // Every output (the media view shows each one's level) and every app stream (the mixer).
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks, root.streams).filter((n, i, all) => n && all.indexOf(n) === i)
    }
}
