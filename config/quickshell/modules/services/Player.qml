pragma Singleton

import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.isPlaying) ?? list[0] ?? null
    }

    readonly property bool active: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""

    // Expanded property for DynamicGlacier-style media integration
    readonly property string trackArtUrl: player?.trackArtUrl ?? ""

    function toggle()   { if (player?.canTogglePlaying) player.togglePlaying() }
    function next()     { if (player?.canGoNext) player.next() }
    function previous() { if (player?.canGoPrevious) player.previous() }
}