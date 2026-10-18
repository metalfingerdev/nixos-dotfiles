pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

// Knows PipeWire. Knows nothing about the island.
// Exposes plain values; consumers react to volumeChanged / mutedChanged.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property int  volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted:  sink?.audio?.muted ?? false

    // Without this, sink.audio stays null: PipeWire objects must be "tracked" to be bound.
    PwObjectTracker { objects: [root.sink] }
}