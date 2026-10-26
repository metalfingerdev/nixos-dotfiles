pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Knows whether something is recording: the microphone or the camera. Knows nothing about the island.
//
// PipeWire: a microphone (audio source node) or camera (video source node) linked to an app's
// stream means it's in use. A camera opened straight through V4L2 (not through PipeWire) is
// caught by polling `fuser /dev/video*`, only on machines that have video devices.
Singleton {
    id: root

    readonly property bool microphone: groups.some(g => isSource(g?.source, PwNodeType.AudioSource) && isStream(g?.target))
    readonly property bool camera: polledCamera
                                || groups.some(g => isSource(g?.source, PwNodeType.VideoSource) && isStream(g?.target))
    readonly property bool active: microphone || camera

    readonly property var groups: Array.from(Pipewire.linkGroups?.values ?? [])

    function has(node, flag) { return node && node.type !== undefined && (node.type & flag) === flag }
    function isSource(node, flag) { return has(node, flag) && !node.isStream }
    function isStream(node) { return !!node && node.isStream }

    // ---- V4L2 cameras that bypass PipeWire ----
    property bool hasVideoDevices: false
    property bool polledCamera: false

    Process {
        running: true
        command: ["sh", "-c", "ls /dev/video* >/dev/null 2>&1 && command -v fuser >/dev/null && echo 1 || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.hasVideoDevices = text.trim() === "1" }
    }

    Process {
        id: poll
        command: ["sh", "-c", "for d in /dev/video*; do fuser \"$d\" >/dev/null 2>&1 && echo 1 && exit; done; echo 0"]
        stdout: StdioCollector { onStreamFinished: root.polledCamera = text.trim() === "1" }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.hasVideoDevices
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }
}
