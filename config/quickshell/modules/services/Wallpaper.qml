pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components

// awww restores the last wallpaper by itself, so at startup this only asks it what is showing.
Singleton {
    id: root

    property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string transition: "fade"       // awww: none fade simple wipe grow center outer wave any random
    property real duration: 0.8

    property var files: []
    property string current: ""
    readonly property int currentIndex: files.indexOf(current)

    ColorQuantizer {
        id: quantizer
        source: root.current ? root.fileUrl(root.current) : ""
        depth: 3
        rescaleSize: 96              // decode small: it only needs the colours
    }
    readonly property var swatches: Array.from(quantizer.colors ?? [])
    // Material's "source colour": the most colourful swatch that isn't near black or white
    readonly property color best: {
        let best = null, score = -1
        for (const c of swatches) {
            const s = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.6)
            if (s > score) { score = s; best = c }
        }
        return best ?? "#4f9d8f"
    }
    // the swatch picked in views/Colours.qml, if any, and the image it belongs to: another image
    // goes back to its own best
    property color picked: "#000000"
    property string pickedFor: ""
    readonly property color seed: pickedFor !== "" && pickedFor === current ? picked : best
    function pick(colour) { picked = colour; pickedFor = current }

    property Store store: Store {
        category: "wallpaper"
        property alias picked: root.picked
        property alias pickedFor: root.pickedFor
    }

    function fileUrl(p) { return "file://" + p.split("/").map(encodeURIComponent).join("/") }
    function baseName(p) { return p ? p.split("/").pop() : "" }

    function reload() { lister.running = true }

    function set(path) {
        if (!path) return
        current = path
        // waits (up to ~10 s) for awww-daemon, so it's safe right after login
        Quickshell.execDetached(["sh", "-c",
            'i=0; until awww query >/dev/null 2>&1; do i=$((i+1)); [ "$i" -gt 50 ] && exit 1; sleep 0.2; done; '
          + 'exec awww img "$1" --transition-type "$2" --transition-duration "$3"',
            "sh", path, transition, String(duration)])
    }

    function step(delta) {
        if (files.length === 0) return
        set(files[(Math.max(0, currentIndex) + delta + files.length) % files.length])
    }

    function random() {
        if (files.length < 2) return set(files[0])
        let i
        do { i = Math.floor(Math.random() * files.length) } while (i === currentIndex)
        set(files[i])
    }

    Component.onCompleted: { query.running = true; reload() }

    // what awww shows now: "<output>: WxH, scale: 1, currently displaying: image: /path"
    Process {
        id: query
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/image:\s*(.+)$/m)
                if (m && root.current === "") root.current = m[1].trim()
            }
        }
    }

    Process {
        id: lister
        command: ["find", "-L", root.dir, "-maxdepth", "1", "-type", "f", "(",
                  "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
                  "-iname", "*.webp", "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(s => s.length > 0).sort((a, b) => a.localeCompare(b))
        }
    }

    IpcHandler {
        target: "wallpaper"

        function next(): void    { root.step(1) }
        function prev(): void    { root.step(-1) }
        function random(): void  { root.random() }
        function reload(): void  { root.reload() }
        function set(path: string): void { root.set(path) }
        function current(): string { return root.current }
    }
}
