import QtQuick
import Quickshell
import Quickshell.Wayland

// Click-through overlay, bottom-left. Remove `Debug {}` from Bar.qml to turn it off.
Scope {
    id: root

    readonly property var st: IslandState.stateTimer
    readonly property var gr: IslandState.graceTimer

    property double stateStart: 0
    property double graceStart: 0
    property double now: Date.now()

    // Timer has no "remaining", so note when it starts and subtract.
    Connections { target: root.st; function onRunningChanged() { if (root.st.running) root.stateStart = Date.now() } }
    Connections { target: root.gr; function onRunningChanged() { if (root.gr.running) root.graceStart = Date.now() } }
    Timer { interval: 50; repeat: true; running: true; onTriggered: root.now = Date.now() }

    function stateText() {
        if (IslandState.stateMs === 0) return "none (stays)"
        if (!st.running)               return "PAUSED (waiting for pointer)"
        return Math.max(0, st.interval - (now - stateStart)).toFixed(0) + " / " + st.interval + " ms"
    }
    function graceText() {
        return gr.running ? Math.max(0, gr.interval - (now - graceStart)).toFixed(0) + " / " + gr.interval + " ms" : "off"
    }
    function stateFraction() {
        if (IslandState.stateMs === 0 || !st.running) return 0
        return Math.max(0, st.interval - (now - stateStart)) / st.interval
    }

    PanelWindow {
        anchors { bottom: true; left: true }
        margins { bottom: 12; left: 12 }
        implicitWidth: 300
        implicitHeight: col.implicitHeight + 20
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}                      // click-through
        color: "#dd000000"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:debug"

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 4

            component Line: Text { color: "#f7f7f7"; font.pixelSize: 12; font.family: "monospace" }

            Line { text: "phase    " + IslandState.phaseNames[IslandState.phase] }
            Line { text: "view     " + (Registry.get(IslandState.view)?.name ?? "?") }
            Line { text: "hovered  " + IslandState.hovered }
            Line { text: "pending  " + (IslandState.pendingView === -1 ? "-" : Registry.get(IslandState.pendingView).name) }
            Line { text: "state    " + root.stateText() }

            Rectangle {
                width: parent.width; height: 4; color: "#2a2a2a"
                Rectangle { width: parent.width * root.stateFraction(); height: parent.height; color: "#f7f7f7" }
            }

            Line { text: "grace    " + root.graceText() }
        }
    }
}