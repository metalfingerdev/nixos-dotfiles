pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Owns the wallpaper list + the current wallpaper. Knows nothing about the island.
//   qs ipc call wallpaper next | prev | random | reload
//   qs ipc call wallpaper set /path/to/image.png
Singleton {
    id: root

    // ---- config ----
    property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string transition: "fade"      // none fade simple wipe grow center outer wave any random ...
    property real duration: 0.8             // seconds
    readonly property string stateFile:
        (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell/wallpaper"

    // ---- state ----
    property var files: []
    property string current: ""
    readonly property int currentIndex: files.indexOf(current)

    function fileUrl(p) { return "file://" + p.split("/").map(encodeURIComponent).join("/") }
    function baseName(p) { return p ? p.split("/").pop() : "" }

    function reload() { lister.running = true }

    function set(path) {
        if (!path) return
        current = path
        apply(path, transition, duration)
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2"', "sh", path, stateFile])
    }

    function step(delta) {
        if (files.length === 0) return
        const i = (Math.max(0, currentIndex) + delta + files.length) % files.length
        set(files[i])
    }

    function random() {
        if (files.length === 0) return
        if (files.length === 1) return set(files[0])
        let i
        do { i = Math.floor(Math.random() * files.length) } while (i === currentIndex)
        set(files[i])
    }

    // Waits (up to ~10s) for awww-daemon, so this is safe to call at login.
    function apply(path, type, dur) {
        Quickshell.execDetached(["sh", "-c",
            'i=0; until awww query >/dev/null 2>&1; do i=$((i+1)); [ "$i" -gt 50 ] && exit 1; sleep 0.2; done; ' +
            'exec awww img "$1" --transition-type "$2" --transition-duration "$3"',
            "sh", path, type, String(dur)])
    }

    // ---- startup: restore last wallpaper, then scan the folder ----
    Component.onCompleted: restore.running = true

    Process {
        id: restore
        command: ["cat", root.stateFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p !== "") {
                    root.current = p
                    root.apply(p, "none", 0)
                }
                root.reload()
            }
        }
    }

    Process {
        id: lister
        command: ["find", "-L", root.dir, "-maxdepth", "1", "-type", "f", "(",
                  "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
                  "-iname", "*.webp", "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n")
                .filter(s => s.length > 0)
                .sort((a, b) => a.localeCompare(b))
        }
    }

    IpcHandler {
        target: "wallpaper"

        function next(): void   { root.step(1) }
        function prev(): void   { root.step(-1) }
        function random(): void { root.random() }
        function reload(): void { root.reload() }
        function set(path: string): void { root.set(path) }
    }
}