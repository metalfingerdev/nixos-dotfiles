import Quickshell.Io
import qs.modules.components

// Strings exist only here. Unknown names are rejected, never silently defaulted.
IpcHandler {
    target: "island"

    // A view opened from here is almost always a keybind: the keyboard is in use, so focus rings
    // and shortcut keycaps show from the start (the pointer moving hides them again).
    function open(name: string): void {
        const e = Registry.byName(name)
        if (!e) return
        Config.focusVisible = true
        Engine.open(e.view)
    }

    function alert(name: string): void {
        const e = Registry.byName(name)
        if (e) Engine.alert(e.view)
    }

    function peek(on: bool): void { Engine.peek(on) }
    function togglePeek(): void   { Engine.togglePeek() }

    function screen(name: string): void { Engine.setScreen(name) }
    function screens(): string           { return Engine.screens().join("\n") }

    function close(): void { Engine.close() }
    function back(): void  { Engine.back() }

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
    function tint(percent: int): void    { Config.tint = Math.max(0, Math.min(1, percent / 100)) }
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
        return JSON.stringify(Object.assign({}, s, {
            view: Registry.name(s.view),
            queued: s.queued < 0 ? null : Registry.name(s.queued),
            history: s.history.map(h => Object.assign({}, h, { view: Registry.name(h.view) })),
            screen: Engine.activeScreen
        }), null, 2)
    }

    function status(): string {
        return Engine.phase + " / " + Registry.name(Engine.view) + " / " + Engine.activeScreen + (Engine.autoHide ? " / autohide" : "")
    }
}