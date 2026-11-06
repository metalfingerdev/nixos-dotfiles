pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property int  volume: level(sink)
    readonly property bool muted:  isMuted(sink)
    readonly property bool hasMic: source !== null
    readonly property int  micVolume: level(source)
    readonly property bool micMuted: isMuted(source)

    readonly property var sinks: Array.from(Pipewire.nodes.values).filter(n => n.isSink && !n.isStream && n.audio)
    // apps' playback streams. To PipeWire a playback stream is a sink as well (sound goes into it),
    // so isSink is true for these too; a recording (a mic stream) isn't one
    readonly property var streams: Array.from(Pipewire.nodes.values).filter(n => n.isSink && n.isStream && n.audio)

    // An app's stream sending sound to an output right now (a stopped one keeps its link, as "paused").
    // Muting a stream takes it out, for an app that holds one open playing silence.
    readonly property var links: Array.from(Pipewire.linkGroups?.values ?? [])
    readonly property bool streaming: links.some(l => l.state === PwLinkState.Active && streams.includes(l.source)
                                                   && sinks.includes(l.target) && !isMuted(l.source))
    // Only after it has lasted: a notification's chime isn't something being played.
    property bool playing: false
    onStreamingChanged: if (!streaming) playing = false
    Timer {
        interval: 10000
        running: root.streaming
        onTriggered: root.playing = true
    }

    function level(node)   { return Math.round((node?.audio?.volume ?? 0) * 100) }
    function isMuted(node) { return node?.audio?.muted ?? false }
    // percent, 0..100; setting a level unmutes
    function setLevel(node, percent) {
        if (!node?.audio) return
        node.audio.muted = false
        node.audio.volume = Math.max(0, Math.min(100, percent)) / 100
    }
    function toggleMuted(node) { if (node?.audio) node.audio.muted = !node.audio.muted }
    function levelIcon(level, muted) {
        return muted ? "volume_off" : level < 34 ? "volume_mute" : level < 67 ? "volume_down" : "volume_up"
    }

    function setVolume(percent) { setLevel(sink, percent) }
    function toggleMute() { toggleMuted(sink) }
    function toggleMic()  { toggleMuted(source) }
    function setSink(node) { if (node) Pipewire.preferredDefaultAudioSink = node }
    function label(node) { return node ? (node.nickname || node.description || node.name || "Output") : "No output" }
    function glyph(node) {
        const n = ((node?.name ?? "") + " " + (node?.description ?? "")).toLowerCase()
        if (n.includes("bluez") || n.includes("headset") || n.includes("headphone")) return "headphones"
        if (n.includes("hdmi") || n.includes("displayport")) return "tv"
        return "speaker"
    }

    function appName(node) {
        const p = node?.properties ?? {}
        return p["application.name"] || node?.description || node?.name || "App"
    }
    // what it plays: a tab's title, a track ("" when it says nothing more than the app's name)
    function mediaName(node) {
        const m = node?.properties?.["media.name"] ?? ""
        return m === appName(node) ? "" : m
    }
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
    // A link's state needs it too.
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks, root.streams, root.links).filter((n, i, all) => n && all.indexOf(n) === i)
    }
}
