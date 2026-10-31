import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    readonly property var s: Engine.snapshot
    readonly property var t: s.timer

    // Timer has no "remaining", so note when the machine hands Engine a new timer object
    // (Engine re-arms exactly then) and subtract.
    property var lastTimer: null
    property double started: 0
    property double now: Date.now()

    Connections {
        target: Engine
        function onSnapshotChanged() {
            if (root.t !== root.lastTimer) { root.lastTimer = root.t; root.started = Date.now() }
        }
    }
    Timer { interval: 50; repeat: true; running: Engine.debug; onTriggered: root.now = Date.now() }

    function left() { return t ? Math.max(0, t.ms - (now - started)) : 0 }
    function timerText() {
        if (!t) return s.ms > 0 ? "PAUSED (held), " + s.ms + " ms" : "none"
        return t.kind + "  " + left().toFixed(0) + " / " + t.ms + " ms"
    }
    function flag(on, label) { return on ? label : "-" }

    PanelWindow {
        visible: Engine.debug
        screen: Engine.screen
        anchors { bottom: true; left: true }
        margins { bottom: 12; left: 12 }
        implicitWidth: 320
        implicitHeight: col.implicitHeight + 20
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        color: "#dd000000"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:debug"

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 4

            component Line: Text { color: "#f7f7f7"; font.pixelSize: 12; font.family: "monospace" }

            Line { text: "phase    " + root.s.phase }
            Line { text: "view     " + Registry.name(root.s.view) + "  (" + root.s.view + ")  prio " + root.s.prio }
            Line { text: "anchor   " + root.s.x }
            Line { text: "screen   " + Engine.activeScreen }
            Line { text: "holding  " + root.flag(root.s.hovered, "hovered") + " " + root.flag(root.s.edge, "edge") + " " + root.flag(root.s.peeking, "peek key") }
            Line { text: "autohide " + root.s.autoHide }
            Line { text: "queued   " + (root.s.queued < 0 ? "-" : Registry.name(root.s.queued) + "  prio " + root.s.queuedPrio) }
            Line { text: "history  " + (root.s.history.length ? root.s.history.map(h => Registry.name(h.view)).join(" > ") : "-") }
            Line { text: "timer    " + root.timerText() }

            Rectangle {
                width: parent.width; height: 4; color: "#2a2a2a"
                Rectangle {
                    width: root.t ? parent.width * root.left() / root.t.ms : 0
                    height: parent.height
                    color: "#f7f7f7"
                }
            }
        }
    }
}
