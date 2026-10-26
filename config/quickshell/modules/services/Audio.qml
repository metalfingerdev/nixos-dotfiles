pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Knows PipeWire. Knows nothing about the island.
// Exposes plain values; consumers react to volumeChanged / mutedChanged.
//   sink    the default output: volume, muted (setVolume, toggleMute)
//   source  the default microphone: micMuted (toggleMic)
//   sinks   every output device, for picking where sound goes (setSink)
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property int  volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted:  sink?.audio?.muted ?? false
    readonly property bool hasMic: source !== null
    readonly property bool micMuted: source?.audio?.muted ?? false

    // hardware outputs only: not the apps' streams
    readonly property var sinks: Array.from(Pipewire.nodes.values).filter(n => n.isSink && !n.isStream && n.audio)

    function setVolume(percent) {
        if (!sink?.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(100, percent)) / 100
    }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted }
    function toggleMic()  { if (source?.audio) source.audio.muted = !source.audio.muted }
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

    // Without this, sink.audio stays null: PipeWire objects must be "tracked" to be bound.
    PwObjectTracker { objects: [root.sink, root.source] }
}
