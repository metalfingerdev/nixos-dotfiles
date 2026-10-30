import Quickshell.Io
import qs.modules.components

// Strings exist only here. Unknown names are rejected, never silently defaulted.
//   qs ipc call island open network        pin a view (opening the open view closes it)
//   qs ipc call island open notifications  the notification center
//   qs ipc call island screen DP-1         show the island on that screen (multi-monitor)
//   qs ipc call island screens             list screen names
//   qs ipc call island alert volume        trigger a toast view
//   qs ipc call island peek true           the rest view (clock) until `peek false`, which hides it
//   qs ipc call island togglePeek          the same from one key: press to show, press again to hide
//   qs ipc call island close
//   qs ipc call island back
//   qs ipc call island autohide true
//   qs ipc call island palette nord        switch colours (`palettes` lists them)
//   qs ipc call island colours wallpaper   where colours come from: preset | accent | wallpaper
//   qs ipc call island accent '#3b6fd8'    a scheme generated from that colour
//   qs ipc call island variant vibrant     tonal | vibrant | muted | mono (generated schemes)
//   qs ipc call island mode light          dark | light (generated schemes)
//   qs ipc call island size 120            the island's size, 80..140 %
//   qs ipc call island style notch         pill | notch
//   qs ipc call island handle strip        auto-hide handle: strip | none
//   qs ipc call island activateLinux false "Activate Linux" in each screen's corner
//   qs ipc call island status
//   qs ipc call island debug true          snapshot overlay + proxy box (toggleDebug flips it)
//   qs ipc call island dump                the full snapshot as JSON
IpcHandler {
    target: "island"

    // A view opened from here is almost always a keybind: the keyboard is in use, so focus rings
    // and shortcut keycaps show from the start (the pointer moving hides them again).
    function open(name: string): void {
        const e = Registry.byName(name)
        if (!e) return
        Config.focusVisible = true
        Engine.open(e.view)                              // no coordinates: centred horizontally, top gap
    }

    function alert(name: string): void {
        const e = Registry.byName(name)
        if (e) Engine.alert(e.view)
    }

    // bind `peek true` to a key's press and `peek false` to its release
    function peek(on: bool): void { Engine.peek(on) }
    // or bind just this, to a key's press
    function togglePeek(): void   { Engine.togglePeek() }

    function screen(name: string): void { Engine.setScreen(name) }
    function screens(): string           { return Engine.screens().join("\n") }

    function close(): void { Engine.close() }
    function back(): void  { Engine.back() }

    // settings
    function autohide(on: bool): void { Engine.setAutoHide(on) }
    function toggleAutohide(): void   { Engine.setAutoHide(!Engine.autoHide) }
    function palette(name: string): void {
        if (Config.palettes[name] === undefined) return
        Config.name = name
        Config.source = "preset"
    }
    function colours(source: string): void { if (["preset", "accent", "wallpaper"].includes(source)) Config.source = source }
    function accent(hex: string): void {
        if (!/^#?[0-9a-fA-F]{6}$/.test(hex)) return
        Config.accent = hex.startsWith("#") ? hex : "#" + hex
        Config.source = "accent"
    }
    function variant(name: string): void { if (["tonal", "vibrant", "muted", "mono"].includes(name)) Config.variant = name }
    function mode(name: string): void    { if (name === "dark" || name === "light") Config.darkMode = name === "dark" }
    function size(percent: int): void    { Config.scale = Math.max(0.8, Math.min(1.4, percent / 100)) }
    function palettes(): string          { return Config.names.join("\n") }
    function style(name: string): void   { if (name === "pill" || name === "notch") Config.style = name }
    function handle(name: string): void  { if (name === "strip" || name === "none") Config.handle = name }
    function activateLinux(on: bool): void { Config.activateLinux = on }
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