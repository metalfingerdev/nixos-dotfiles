import Quickshell.Io

// Strings exist only here. Unknown names are rejected, never silently defaulted.
//   qs ipc call island open network        pin a view (opening the open view closes it)
//   qs ipc call island open notifications  the notification center
//   qs ipc call island screen DP-1         show the island on that screen (multi-monitor)
//   qs ipc call island screens             list screen names
//   qs ipc call island alert volume        trigger a toast view
//   qs ipc call island peek true           hover from the keyboard: the peek view until `peek false`
//   qs ipc call island close
//   qs ipc call island back
//   qs ipc call island autohide true
//   qs ipc call island status
//   qs ipc call island debug true          snapshot overlay + proxy box (toggleDebug flips it)
//   qs ipc call island dump                the full snapshot as JSON
IpcHandler {
    target: "island"

    function open(name: string): void {
        const e = Registry.byName(name)
        if (e) Engine.open(e.view)                       // no coordinates: centred horizontally, top gap
    }

    function alert(name: string): void {
        const e = Registry.byName(name)
        if (e) Engine.alert(e.view)
    }

    // bind `peek true` to a key's press and `peek false` to its release
    function peek(on: bool): void { Engine.peek(on) }

    function screen(name: string): void { Engine.setScreen(name) }
    function screens(): string           { return Engine.screens().join("\n") }

    function close(): void { Engine.close() }
    function back(): void  { Engine.back() }

    // settings
    function autohide(on: bool): void { Engine.setAutoHide(on) }
    function toggleAutohide(): void   { Engine.setAutoHide(!Engine.autoHide) }
    function debug(on: bool): void    { Engine.debug = on }
    function toggleDebug(): void      { Engine.debug = !Engine.debug }

    // view numbers are resolved to names, so the output reads without the enum at hand
    function dump(): string {
        const s = Engine.snapshot
        const n = v => { const e = Registry.get(v); return e ? e.name : v }
        return JSON.stringify(Object.assign({}, s, {
            view: n(s.view),
            queued: s.queued < 0 ? null : n(s.queued),
            history: s.history.map(h => Object.assign({}, h, { view: n(h.view) })),
            screen: Engine.activeScreen
        }), null, 2)
    }

    function status(): string {
        const e = Registry.get(Engine.view)
        return Engine.phase + " / " + (e ? e.name : "?") + " / " + Engine.activeScreen + (Engine.autoHide ? " / autohide" : "")
    }
}