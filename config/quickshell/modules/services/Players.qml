pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Knows MPRIS media players. Knows nothing about the island.
//
// active: the player to show and control: the one the user picked (while it still exists), else
//         one that is playing, else the first.
Singleton {
    id: root

    readonly property var list: Array.from(Mpris.players.values)

    property var picked: null
    readonly property var active: (picked && list.includes(picked)) ? picked
                                : list.find(p => p.isPlaying) ?? list[0] ?? null

    // cycle through the players (the view's "switch player" button)
    function pickNext() {
        if (list.length < 2) return
        picked = list[(list.indexOf(active) + 1) % list.length]
    }

    // MPRIS doesn't push the position: it has to be asked for. Whoever shows it holds a
    // watch(true) while it is on screen, and the position refreshes once a second while playing.
    property int watchers: 0
    function watch(on) { watchers = Math.max(0, watchers + (on ? 1 : -1)) }
    Timer {
        interval: 1000
        repeat: true
        running: root.watchers > 0 && (root.active?.isPlaying ?? false)
        onTriggered: root.active.positionChanged()
    }

    function toggle()   { if (active?.canTogglePlaying) active.togglePlaying() }
    function next()     { if (active?.canGoNext) active.next() }
    function previous() { if (active?.canGoPrevious) active.previous() }
    function seek(fraction) {
        if (active?.canSeek && active.lengthSupported) active.position = fraction * active.length
    }
}
