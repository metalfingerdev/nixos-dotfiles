pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// length / position / canSeek are the last GOOD values for the current track: players report junk for
// a moment after a seek or while buffering (lengthSupported false, a bogus length, canSeek false).
Singleton {
    id: root

    readonly property var list: Array.from(Mpris.players.values)

    property var picked: null
    readonly property var active: (picked && list.includes(picked)) ? picked
                                : list.find(p => p.isPlaying) ?? list[0] ?? null
    readonly property bool playing: active?.isPlaying ?? false
    // any player, not just the active one: a picked player can be paused while another plays
    readonly property bool anyPlaying: list.some(p => p.isPlaying)
    readonly property bool hasTrack: (active?.trackTitle ?? "") !== ""

    property real length: 0              // seconds; 0 = unknown
    property real rawPosition: 0
    property bool seekable: false
    readonly property real position: length > 0 ? Math.min(rawPosition, length) : rawPosition
    readonly property bool canSeek: seekable && length > 0

    function refresh() {
        const p = active
        if (!p) return
        const len = p.lengthSupported ? Number(p.length) : NaN
        if (isFinite(len) && len > 0) { length = len; seekable = p.canSeek }
        const pos = p.positionSupported ? Number(p.position) : NaN
        if (isFinite(pos) && pos >= 0) rawPosition = pos
    }

    // A new track (or player) forgets the old values. An empty title is a metadata glitch, not a track.
    readonly property string track: (active?.uniqueId ?? "") + "\u0000" + (active?.trackTitle ?? "")
                                  + "\u0000" + (active?.trackArtist ?? "")
    onTrackChanged: {
        if (active && active.trackTitle === "") return
        length = 0; rawPosition = 0; seekable = false
        refresh()
    }
    onActiveChanged: refresh()

    Connections {
        target: root.active
        ignoreUnknownSignals: true
        function onPositionChanged() { root.refresh() }
        function onLengthChanged()   { root.refresh() }
        function onCanSeekChanged()  { root.refresh() }
    }

    // MPRIS doesn't push the position: it has to be asked for. Whoever shows it holds a
    // watch(true) while it's on screen. Not tied to `playing`: a wrong playback state while
    // buffering must not freeze the bar.
    property int watchers: 0
    function watch(on) { watchers = Math.max(0, watchers + (on ? 1 : -1)) }
    Timer {
        interval: 250
        repeat: true
        running: root.watchers > 0 && root.active !== null
        onTriggered: root.active.positionChanged()        // the Connections above calls refresh()
    }

    // Some players can't toggle but can play and pause separately.
    readonly property bool canToggle: !!active && (active.canTogglePlaying || active.canPlay || active.canPause)
    function toggle() {
        const p = active
        if (!p) return
        if (p.canTogglePlaying) p.togglePlaying()
        else if (p.isPlaying && p.canPause) p.pause()
        else if (!p.isPlaying && p.canPlay) p.play()
    }
    function next()     { if (active?.canGoNext) active.next() }
    function previous() { if (active?.canGoPrevious) active.previous() }

    readonly property bool shuffle: active?.shuffle ?? false
    readonly property string loop: active?.loopState === MprisLoopState.Track ? "track"
                                 : active?.loopState === MprisLoopState.Playlist ? "playlist" : "none"
    function toggleShuffle() { if (active?.shuffleSupported) active.shuffle = !active.shuffle }
    function cycleLoop() {
        if (!active?.loopSupported) return
        active.loopState = loop === "none" ? MprisLoopState.Track
                         : loop === "track" ? MprisLoopState.Playlist : MprisLoopState.None
    }
    function seek(fraction) {
        if (!canSeek) return
        rawPosition = fraction * length                    // show it at once; the player catches up
        active.position = rawPosition
        active.positionChanged()
    }
}
