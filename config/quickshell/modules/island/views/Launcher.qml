import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Search apps, files and the island's own actions, with filter chips: All, Apps, Files, Actions.
//   apps      ranked: the name starts with the query > a word in it does > the name contains it >
//             its generic name or keywords do ("browser" finds Firefox) > the query's letters in
//             order ("ffx"). Ties go to the app launched most, then the shorter name. With no
//             query: the most launched apps. Terminal apps (Terminal=true) open in kitty
//   files     names under ~ (5 levels, hidden folders skipped), from 2 letters; opened with xdg-open
//   actions   the island's views and quick settings, lock, suspend...
//   math      "12*7+3" shows the result; Enter copies it
// Keys: type to filter, Up/Down select, Enter runs, Tab / Shift+Tab change the filter, Escape
// closes, Backspace on an empty field goes back. The pointer only takes the selection when it moves.
// Text typed into the glance's search bar (Engine.query) arrives already in the field.
Item {
    id: root

    readonly property int maxRows: 7         // shown at once; the rest scroll
    readonly property int maxResults: 24     // per source
    readonly property int rowH: 64
    readonly property string terminal: "kitty"
    readonly property var filters: [
        { key: "all",     label: "All" },
        { key: "apps",    label: "Apps" },
        { key: "files",   label: "Files" },
        { key: "actions", label: "Actions" }
    ]
    property string filter: "all"
    property int selected: 0
    readonly property string query: bar.text.trim().toLowerCase()

    // ---- how often each app was launched (remembered) ----
    property string usesJson: "{}"
    property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini"
        category: "launcher"
        property alias uses: root.usesJson
    }
    readonly property var uses: { try { return JSON.parse(usesJson) } catch (e) { return {} } }
    function used(app) { return uses[app.id] ?? 0 }
    function count(app) {
        const u = Object.assign({}, uses)
        u[app.id] = (u[app.id] ?? 0) + 1
        usesJson = JSON.stringify(u)
    }

    // ---- apps ----
    // 0 = no match; higher = better
    function score(app, q) {
        const name = app.name.toLowerCase()
        if (name.startsWith(q)) return 500
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 400
        if (name.includes(q)) return 300
        const extra = [app.genericName ?? "", String(app.keywords ?? ""), app.id ?? ""].join(" ").toLowerCase()
        if (extra.includes(q)) return 200
        let i = 0
        for (const c of name) if (c === q[i]) i++
        return i === q.length ? 100 : 0
    }
    readonly property var apps: {
        const q = query
        const all = Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay)
        const ranked = q === ""
            ? all.map(a => ({ app: a, score: used(a) > 0 ? 1 : 0 }))
            : all.map(a => ({ app: a, score: score(a, q) })).filter(m => m.score > 0)
        return ranked
            .sort((a, b) => (b.score - a.score) || (used(b.app) - used(a.app)) || (a.app.name.length - b.app.name.length)
                            || a.app.name.localeCompare(b.app.name))
            .slice(0, maxResults)
            .map(m => ({ kind: "app", app: m.app, name: m.app.name,
                         description: m.app.comment || m.app.genericName || "" }))
    }

    // ---- actions ----
    function view(v) { return () => Engine.open(v) }
    function quit(f) { return () => { Engine.close(); f() } }
    readonly property var actions: [
        { name: "Tabs", description: "Every view, and the workspaces", icon: Config.symbol.hub, keys: "hub all views", run: view(Engine.View.Tabs) },
        { name: "Dashboard", description: "Quick settings, media and notifications", icon: Config.symbol.dashboard, run: view(Engine.View.Dashboard) },
        { name: "Wi-Fi", description: "Networks and connections", icon: "wifi", keys: "network internet wlan ethernet", run: view(Engine.View.Network) },
        { name: "Bluetooth", description: "Devices", icon: "bluetooth", keys: "headphones pair", run: view(Engine.View.Bluetooth) },
        { name: "Notifications", description: "Everything that arrived", icon: Config.symbol.notifications, run: view(Engine.View.Notifications) },
        { name: "Media", description: "What's playing", icon: Config.symbol.media, keys: "music player song", run: view(Engine.View.Media) },
        { name: "Workspaces", description: "Overview of every workspace", icon: Config.symbol.overview, keys: "overview windows", run: view(Engine.View.Workspaces) },
        { name: "Calendar", description: "The month, with today", icon: Config.symbol.calendar, keys: "clock date time", run: view(Engine.View.Clock) },
        { name: "Battery", description: "Charge, time left and health", icon: Config.symbol.battery, keys: "power energy", run: view(Engine.View.Battery) },
        { name: "Theme", description: "Colours, the island's shape, wallpaper", icon: Config.symbol.theme, keys: "settings appearance colour color", run: view(Engine.View.Theme) },
        { name: "Random wallpaper", description: "From ~/Pictures/Wallpapers", icon: "wallpaper", keys: "background", run: () => Wallpaper.random() },
        { name: "Do not disturb", description: Notifier.dnd ? "On: turn it off" : "Off: turn it on", icon: Config.symbol.dnd, keys: "dnd quiet silence", run: quit(() => Notifier.dnd = !Notifier.dnd) },
        { name: "Screenshot", description: "Select an area; saved and copied", icon: Config.symbol.screenshot, keys: "capture grab", run: quit(() => Toggles.screenshot()) },
        { name: "Lock", description: "Lock the session", icon: "lock", run: quit(() => Session.run("lock")) },
        { name: "Suspend", description: "Sleep", icon: "bedtime", keys: "sleep", run: quit(() => Session.run("suspend")) },
        { name: "Power", description: "Log out, restart, shut down", icon: Config.symbol.power, keys: "logout reboot restart shutdown poweroff", run: view(Engine.View.Power) }
    ]
    readonly property var actionRows: {
        const q = query
        return actions
            .filter(a => q === "" || (a.name + " " + (a.keys ?? "")).toLowerCase().split(/\s+/).some(w => w.startsWith(q))
                                  || a.name.toLowerCase().includes(q))
            .map(a => ({ kind: "action", name: a.name, description: a.description, icon: a.icon, run: a.run }))
    }

    // ---- math ----
    readonly property var calc: {
        const q = bar.text.trim()
        if (!/^[\d\s+\-*/%^().,]+$/.test(q) || !/\d/.test(q) || !/[+\-*/%^]/.test(q)) return null
        try {
            // digits and operators only (checked above), so this can't run anything else
            const v = Function('"use strict"; return (' + q.replace(/\^/g, "**").replace(/,/g, ".") + ")")()
            if (typeof v !== "number" || !isFinite(v)) return null
            const shown = String(Math.round(v * 1e10) / 1e10)
            return { kind: "calc", name: "= " + shown, value: shown, description: "Enter copies it", icon: "calculate" }
        } catch (e) { return null }
    }

    // ---- files (a background `find`, a moment after typing stops) ----
    property var files: []
    property string searched: ""
    property bool pending: false
    readonly property bool wantFiles: (filter === "all" || filter === "files") && query.length >= 2
    onQueryChanged: {
        selected = 0
        files = []
        if (wantFiles) debounce.restart()
    }
    onFilterChanged: {
        selected = 0
        if (wantFiles && searched !== query) debounce.restart()
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: root.find()
    }
    function find() {
        if (finder.running) { pending = true; return }
        searched = query
        finder.command = ["sh", "-c", "find \"$HOME\" -mindepth 1 -maxdepth 5 \\( -name '.*' -o -name node_modules -o -name target -o -name __pycache__ \\) -prune "
                                   + "-o -iname \"*$1*\" -print 2>/dev/null | head -n 60", "sh", searched]
        finder.running = true
    }
    Process {
        id: finder
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.searched !== root.query) return
                const home = Quickshell.env("HOME")
                const q = root.query
                root.files = text.split("\n").filter(p => p !== "")
                    .map(p => ({ path: p, base: p.split("/").pop() }))
                    .sort((a, b) => (b.base.toLowerCase().startsWith(q) - a.base.toLowerCase().startsWith(q))
                                    || (a.path.split("/").length - b.path.split("/").length) || a.base.localeCompare(b.base))
                    .slice(0, root.maxResults)
                    .map(f => ({ kind: "file", name: f.base, path: f.path, icon: root.fileGlyph(f.base),
                                 description: "~" + f.path.slice(home.length, f.path.length - f.base.length - 1) }))
            }
        }
        onExited: if (root.pending) { root.pending = false; root.find() }
    }
    function fileGlyph(name) {
        const ext = name.includes(".") ? name.split(".").pop().toLowerCase() : ""
        if (ext === "") return "folder"
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "bmp"].includes(ext)) return "image"
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext)) return "movie"
        if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].includes(ext)) return "music_note"
        if (["pdf"].includes(ext)) return "picture_as_pdf"
        if (["zip", "tar", "gz", "xz", "7z", "zst", "rar"].includes(ext)) return "folder_zip"
        if (["nix", "qml", "js", "ts", "py", "rs", "go", "c", "h", "lua", "sh", "json", "toml"].includes(ext)) return "code"
        return "description"
    }

    // ---- what shows, in order ----
    readonly property var results: {
        const out = []
        if (calc) out.push(calc)
        if (filter === "all" || filter === "apps") out.push(...apps)
        if (filter === "actions" || (filter === "all" && query !== "")) out.push(...actionRows)
        if (filter === "all" || filter === "files") out.push(...files)
        return out
    }
    onResultsChanged: selected = Math.min(selected, Math.max(0, results.length - 1))
    onSelectedChanged: list.positionViewAtIndex(selected, ListView.Contain)

    // an empty list says why
    readonly property string hint: results.length > 0 ? ""
        : filter === "files" && query.length < 2 ? "Type at least two letters to search your files"
        : finder.running || debounce.running ? "Searching…"
        : query !== "" ? "Nothing matches “" + bar.text.trim() + "”" : "Nothing here"

    function run(row) {
        if (!row) return
        switch (row.kind) {
        case "app":
            count(row.app)
            if (row.app.runInTerminal)
                Quickshell.execDetached({ command: [terminal, "-e"].concat(row.app.command), workingDirectory: row.app.workingDirectory })
            else
                row.app.execute()
            Engine.close()
            break
        case "file":   Toggles.open(row.path); Engine.close(); break
        case "calc":   Quickshell.clipboardText = row.value; Engine.close(); break
        case "action": row.run(); break
        }
    }
    function cycle(step) {
        const i = filters.findIndex(f => f.key === filter)
        filter = filters[(i + step + filters.length) % filters.length].key
    }

    Component.onCompleted: {
        if (Engine.query !== "") {
            bar.text = Engine.query
            bar.field.cursorPosition = bar.text.length
            Engine.query = ""
        }
    }

    implicitWidth: 800
    implicitHeight: 20 + bar.height + 12 + (results.length > 0 ? list.height : 56) + 18

    // back: to the hub (Tabs), like every other view
    Pill {
        id: back
        x: 16
        anchors.verticalCenter: bar.verticalCenter
        kind: "text"
        icon: Config.symbol.back
        iconSize: 24
        implicitHeight: 52
        activeFocusOnTab: false             // Backspace on an empty field, or Escape, does the same
        onClicked: Engine.back()
    }

    SearchBar {
        id: bar
        x: back.x + back.width + 8; y: 20
        width: parent.width - x - 20
        implicitHeight: 60
        fieldSize: 18
        placeholder: "Search"
        takesTab: true
        takesArrows: true
        focus: true

        onKey: Engine.key()
        onDown: root.selected = root.results.length ? (root.selected + 1) % root.results.length : 0
        onUp: root.selected = root.results.length ? (root.selected - 1 + root.results.length) % root.results.length : 0
        onAccepted: root.run(root.results[root.selected])
        onTab: backward => root.cycle(backward ? -1 : 1)
        onEscaped: Engine.close()
        onBackspaceEmpty: Engine.back()

        Repeater {
            model: root.filters

            Chip {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                selected: root.filter === modelData.key
                activeFocusOnTab: false
                onClicked: root.filter = modelData.key
            }
        }
    }

    Text {
        visible: root.hint !== ""
        x: 36
        y: bar.y + bar.height + 28
        text: root.hint
        color: Config.dim
        font.family: Config.font
        font.pixelSize: Config.body
    }

    ListView {
        id: list
        x: 20
        y: bar.y + bar.height + 12
        width: parent.width - 40
        height: Math.min(root.results.length, root.maxRows) * (root.rowH + spacing)
        spacing: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: index === root.selected

            width: list.width
            height: root.rowH
            radius: Config.innerRadius
            color: current ? Config.secondary : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            // an app's own icon, or a glyph in a tonal circle
            Item {
                id: lead
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44

                // "" when the theme has no such icon: then the glyph circle shows instead
                readonly property string appIcon: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.app.icon ?? "", true) : ""

                IconImage {
                    visible: lead.appIcon !== ""
                    anchors.centerIn: parent
                    implicitSize: 40
                    asynchronous: true
                    source: lead.appIcon
                }
                Rectangle {
                    visible: lead.appIcon === ""
                    anchors.fill: parent
                    radius: 22
                    color: row.current ? Config.primary : Config.high

                    Icon {
                        anchors.centerIn: parent
                        name: row.modelData.icon ?? "apps"
                        size: 20
                        color: row.current ? Config.primaryInk : Config.text
                    }
                }
            }

            Column {
                anchors { left: lead.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                spacing: 2

                Text {
                    width: parent.width
                    text: row.modelData.name
                    elide: Text.ElideRight
                    color: row.current ? Config.secondaryInk : Config.text
                    font.family: Config.font
                    font.pixelSize: Config.body + 2
                    font.weight: Font.Medium
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.description ?? ""
                    elide: Text.ElideRight
                    color: row.current ? Config.mix(Config.secondaryInk, Config.secondary, 0.25) : Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.small + 1
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property point last: Qt.point(-1, -1)
                // only a real move takes the selection: a pointer resting where a row appears
                // under it must not fight the keyboard
                onPositionChanged: mouse => {
                    const p = mapToGlobal(mouse.x, mouse.y)
                    if (Math.abs(p.x - last.x) > 0.5 || Math.abs(p.y - last.y) > 0.5) {
                        if (last.x >= 0) root.selected = row.index
                        last = p
                    }
                }
                onClicked: root.run(row.modelData)
            }
        }
    }
}
