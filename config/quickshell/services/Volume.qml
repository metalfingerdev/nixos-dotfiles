// Volume.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.services

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.ready && sink?.audio ? sink.audio.volume : 0
    readonly property bool muted:  sink?.ready && sink?.audio ? sink.audio.muted  : false
    readonly property int percent: Math.round(volume * 100)

    PwObjectTracker { objects: [root.sink] }

    // Any real volume/mute change -> flash the compact bar view.
    // Also keeps this singleton alive/bound even if nothing else references it.
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { BarState.showBarView("audio") }
        function onMutedChanged()  { BarState.showBarView("audio") }
    }

    function setVolume(v: real): void {
        if (!sink?.ready || !sink?.audio) return
        sink.audio.muted  = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function increase(step: real): void { setVolume(volume + (step > 0 ? step : 0.05)) }
    function decrease(step: real): void { setVolume(volume - (step > 0 ? step : 0.05)) }

    function toggleMute(): void {
        if (sink?.ready && sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    IpcHandler {
        target: "volume"

        // qs ipc call volume get
        function get(): int { return root.percent }
        // qs ipc call volume set 40
        function set(v: int): void { root.setVolume(v / 100) }
        // qs ipc call volume increase 5
        function increase(step: int): void { root.increase(step / 100) }
        // qs ipc call volume decrease 5
        function decrease(step: int): void { root.decrease(step / 100) }
        // qs ipc call volume toggleMute
        function toggleMute(): void { root.toggleMute() }
    }
}