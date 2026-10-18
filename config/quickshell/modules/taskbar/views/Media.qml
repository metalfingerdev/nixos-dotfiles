import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.modules.taskbar
import qs.modules.services

FocusScope {
    id: root

    Component.onCompleted: {
        root.forceActiveFocus()
        refresh()
    }
    onVisibleChanged: {
        if (visible) root.forceActiveFocus()
    }

    property bool keyboardActive: false
    // dragging the seek bar also counts as "working in the view", so the island won't expire mid-drag
    readonly property bool engaged: keyboardActive || progress.dragging

    Keys.onPressed: (event) => {
        keyboardActive = true
        if (event.key === Qt.Key_Backspace) {
            IslandState.send(IslandState.Event.Back)
            event.accepted = true
        } else {
            event.accepted = false
        }
    }

    // ---- player values (MPRIS: seconds) ----
    // Players drop length/position/canSeek for a while after a seek or while buffering,
    // so we keep the last good values for the current track and use those.
    readonly property var mp: Player.player

    property real goodLen: 0
    property real goodPos: 0
    property bool goodCanSeek: false

    readonly property real trackLen: goodLen
    readonly property real trackPos: goodLen > 0 ? Math.min(goodPos, goodLen) : 0
    readonly property bool canSeek: goodCanSeek && goodLen > 0

    function refresh() {
        const m = root.mp
        if (!m) return

        // Only trust the length when the player says it's supported; right after a seek
        // players report lengthSupported=false with a junk value, so we keep the last good one.
        const len = (m.lengthSupported ?? false) ? Number(m.length) : NaN
        if (isFinite(len) && len > 0) {
            goodLen = len
            goodCanSeek = m.canSeek ?? false
        }

        const pos = (m.positionSupported ?? false) ? Number(m.position) : NaN
        if (isFinite(pos) && pos >= 0) goodPos = pos
    }

    // New track -> forget the old values. Ignore an empty title (that's a metadata glitch, not a new track).
    readonly property string trackKey: Player.title + "\u0000" + Player.artist
    onTrackKeyChanged: {
        if (Player.title === "") return
        goodLen = 0
        goodPos = 0
        goodCanSeek = false
        refresh()
    }

    onMpChanged: refresh()

    Connections {
        target: root.mp
        ignoreUnknownSignals: true
        function onPositionChanged() { root.refresh() }
        function onLengthChanged()   { root.refresh() }
    }

    // MPRIS doesn't push position updates, so poll. Deliberately not tied to Player.playing:
    // a wrong playback state while buffering must not freeze the bar.
    Timer {
        interval: 250
        repeat: true
        running: root.visible && root.mp !== null
        onTriggered: root.mp.positionChanged()      // the Connections above calls refresh()
    }

    function fmt(s) {
        if (!isFinite(s) || s < 0) s = 0
        const t = Math.floor(s)
        const h = Math.floor(t / 3600)
        const m = Math.floor((t % 3600) / 60)
        const sec = t % 60
        const pad = n => (n < 10 ? "0" : "") + n
        return h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : m + ":" + pad(sec)
    }

    // ---- size: 1.5x the previous 460x150 ----
    implicitWidth: 690
    implicitHeight: 225

    Row {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // Album art or fallback icon
        Rectangle {
            id: artBox
            width: 177
            height: 177
            radius: 21
            color: "#222222"
            clip: true

            Image {
                id: art
                anchors.fill: parent
                source: Player.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "🎵"
                font.pixelSize: 48
                visible: !art.visible
            }
        }

        // Info, progress, controls
        Column {
            width: parent.width - artBox.width - parent.spacing
            spacing: 12
            anchors.verticalCenter: parent.verticalCenter

            // Title / artist
            Column {
                width: parent.width
                spacing: 3

                Text {
                    width: parent.width
                    text: Player.active ? (Player.title !== "" ? Player.title : "Unknown Track") : "No media playing"
                    color: "#f7f7f7"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: Player.active ? (Player.artist !== "" ? Player.artist : "Unknown Artist") : "Waiting for player..."
                    color: "#aaaaaa"
                    font.pixelSize: 18
                    elide: Text.ElideRight
                }
            }

            // Progress bar + times
            Column {
                width: parent.width
                spacing: 0

                Progress {
                    id: progress
                    width: parent.width
                    height: 24
                    thickness: 6
                    fraction: root.trackLen > 0 ? root.trackPos / root.trackLen : 0
                    seekable: root.canSeek
                    onSeeked: (f) => {
                        if (!root.canSeek) return
                        root.mp.position = f * root.trackLen
                        root.mp.positionChanged()
                    }
                }

                Item {
                    width: parent.width
                    height: 21

                    Text {
                        anchors.left: parent.left
                        text: root.trackLen > 0 ? root.fmt(progress.dragging ? progress.shownFraction * root.trackLen : root.trackPos) : ""
                        color: "#aaaaaa"
                        font.pixelSize: 16
                    }

                    Text {
                        anchors.right: parent.right
                        text: root.trackLen > 0 ? root.fmt(root.trackLen) : ""
                        color: "#aaaaaa"
                        font.pixelSize: 16
                    }
                }
            }

            // Controls
            RowLayout {
                width: parent.width
                spacing: 12
                uniformCellSizes: true          // four equal cells, so toggling ⏸/▶ never shifts anything

                Pill {
                    text: "⏮"
                    fontSize: 19
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    active: Player.player?.canGoPrevious ?? false
                    onClicked: Player.previous()
                }

                Pill {
                    text: Player.playing ? "⏸" : "▶"
                    fontSize: 19
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    active: Player.player?.canTogglePlaying ?? false
                    onClicked: Player.toggle()
                }

                Pill {
                    text: "⏭"
                    fontSize: 19
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    active: Player.player?.canGoNext ?? false
                    onClicked: Player.next()
                }

                Pill {
                    text: "↩"
                    fontSize: 19
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: IslandState.openHome()
                }
            }
        }
    }
}