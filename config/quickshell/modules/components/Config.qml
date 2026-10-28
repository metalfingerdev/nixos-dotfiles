pragma Singleton

import QtQuick
import QtCore

// Colours, shape and type for the whole island, after Material 3 (Android's quick settings):
// tonal surfaces, pill tiles, thick pill sliders, the primary colour for "on". Bar, the components
// and every view read these; nothing else hard-codes a colour. `name` picks a palette
// (views/Theme.qml, IPC `palette`) and is remembered across restarts. No view file may be called
// Config.qml: views see their own folder first, and it would hide this singleton from every view.
//
// Plain QtQuick + QtCore (no Quickshell), so modules/tests/tst_keyboard.qml can still load Pill.
QtObject {
    id: root

    // Every palette has the same keys, Material 3 roles:
    //   surface     the island itself                    container   tiles, cards, fields (off)
    //   high        hover, slider tracks, icon circles   highest     pressed, keyboard focus
    //   primary     "on": active tiles, sliders, the play button      onPrimary   text/icons on it
    //   secondary   selected chips and segments (a quieter "on")      onSecondary text/icons on it
    // (QML reads a property called onX as a signal handler, so those two are primaryInk and
    // secondaryInk below.)
    //   text        primary text      dim   secondary text      outline   borders, placeholders
    //   good, warn, bad   status
    readonly property var palettes: ({
        teal:     { label: "Teal", dark: true, surface: "#0e1514", container: "#1a2120", high: "#252b2a", highest: "#303635",
                    primary: "#80d5c8", onPrimary: "#003731", secondary: "#334b47", onSecondary: "#cce8e2",
                    text: "#dde4e2", dim: "#bec9c6", outline: "#6f7977",
                    good: "#8bd5a0", warn: "#f2c36b", bad: "#ffb4ab" },
        blue:     { label: "Blue", dark: true, surface: "#111318", container: "#1d2024", high: "#282a2f", highest: "#33353a",
                    primary: "#a8c7fa", onPrimary: "#062e6f", secondary: "#3e4759", onSecondary: "#d9e3f8",
                    text: "#e2e2e9", dim: "#c4c6d0", outline: "#72777f",
                    good: "#8fd69c", warn: "#f0c46a", bad: "#ffb4ab" },
        graphite: { label: "Graphite", dark: true, surface: "#121212", container: "#1e1e1e", high: "#2a2a2a", highest: "#363636",
                    primary: "#e8e8e8", onPrimary: "#141414", secondary: "#3a3a3a", onSecondary: "#ececec",
                    text: "#f2f2f2", dim: "#b4b4b4", outline: "#767676",
                    good: "#7ee2a8", warn: "#ffcc66", bad: "#ff6b6b" },
        midnight: { label: "Midnight", dark: true, surface: "#0b0f1a", container: "#151b2b", high: "#202840", highest: "#2a3452",
                    primary: "#7aa2f7", onPrimary: "#0b1530", secondary: "#2a3452", onSecondary: "#d6e0fb",
                    text: "#e8ecf7", dim: "#a9b3cc", outline: "#5a6585",
                    good: "#9ece6a", warn: "#e0af68", bad: "#f7768e" },
        nord:     { label: "Nord", dark: true, surface: "#2e3440", container: "#3b4252", high: "#434c5e", highest: "#4c566a",
                    primary: "#88c0d0", onPrimary: "#22303a", secondary: "#4c566a", onSecondary: "#e5e9f0",
                    text: "#eceff4", dim: "#c3cad6", outline: "#7b879c",
                    good: "#a3be8c", warn: "#ebcb8b", bad: "#bf616a" },
        rose:     { label: "Rosé", dark: true, surface: "#191724", container: "#1f1d2e", high: "#26233a", highest: "#393552",
                    primary: "#ebbcba", onPrimary: "#2a1f2b", secondary: "#393552", onSecondary: "#e0def4",
                    text: "#e0def4", dim: "#aba7c4", outline: "#6e6a86",
                    good: "#9ccfd8", warn: "#f6c177", bad: "#eb6f92" },
        forest:   { label: "Forest", dark: true, surface: "#11150f", container: "#1b2118", high: "#262e22", highest: "#323c2d",
                    primary: "#a7c080", onPrimary: "#1c2a10", secondary: "#323c2d", onSecondary: "#dfe8d2",
                    text: "#e6eadf", dim: "#b4bdab", outline: "#69745f",
                    good: "#83c092", warn: "#dbbc7f", bad: "#e67e80" },
        paper:    { label: "Paper", dark: false, surface: "#f4f4f1", container: "#e8e8e4", high: "#dcdcd7", highest: "#d0d0ca",
                    primary: "#2f6fde", onPrimary: "#ffffff", secondary: "#d6e2fa", onSecondary: "#0f2a5c",
                    text: "#1c1c1e", dim: "#4c4c52", outline: "#8e8e93",
                    good: "#2e9b5f", warn: "#b7791f", bad: "#d64545" }
    })
    readonly property var names: Object.keys(palettes)

    // ---- where the colours come from (views/Theme.qml) ----
    //   source   "preset": a palette above, by `name`
    //            "accent": generated from `accent`, Material You style
    //            "wallpaper": generated from the wallpaper's dominant colour (`wallpaperSeed`,
    //                         kept up to date by shell.qml from services/Wallpaper.qml)
    //   variant  how colourful a generated scheme is: "tonal" | "vibrant" | "muted" | "mono"
    //   darkMode a generated scheme's light or dark version
    property string source: "preset"
    property string name: "teal"
    property color accent: "#4f9d8f"
    property color wallpaperSeed: "#4f9d8f"
    property string variant: "tonal"
    property bool darkMode: true
    readonly property color seed: source === "wallpaper" ? wallpaperSeed : accent
    readonly property var current: source === "preset" ? (palettes[name] ?? palettes.teal) : scheme(seed, variant, darkMode)

    // A whole palette from one colour: the seed's hue at Material's tones for each role, with
    // a saturation per role set by the variant. HSL, not Material's HCT, so tones are approximate.
    function scheme(seed, variant, dark) {
        const h = Math.max(0, seed.hslHue)
        const c = ({ tonal:   { p: 0.50, s: 0.22, n: 0.10 },
                     vibrant: { p: 0.82, s: 0.40, n: 0.16 },
                     muted:   { p: 0.28, s: 0.12, n: 0.05 },
                     mono:    { p: 0,    s: 0,    n: 0 } })[variant] ?? { p: 0.5, s: 0.22, n: 0.1 }
        const mono = variant === "mono"
        const tone = (sat, light) => Qt.hsla(h, sat, light, 1)
        return dark ? {
            label: "Generated", dark: true,
            surface: tone(c.n, 0.065), container: tone(c.n, 0.105), high: tone(c.n, 0.145), highest: tone(c.n, 0.185),
            primary: tone(c.p, mono ? 0.90 : 0.72), onPrimary: tone(c.p, mono ? 0.10 : 0.14),
            secondary: tone(c.s, 0.26), onSecondary: tone(c.s, 0.88),
            text: tone(c.n, 0.91), dim: tone(c.n, 0.75), outline: tone(c.n, 0.52),
            good: "#8bd5a0", warn: "#f2c36b", bad: "#ffb4ab"
        } : {
            label: "Generated", dark: false,
            surface: tone(c.n, 0.975), container: tone(c.n, 0.935), high: tone(c.n, 0.895), highest: tone(c.n, 0.855),
            primary: tone(c.p, mono ? 0.12 : 0.40), onPrimary: tone(c.p, 0.985),
            secondary: tone(c.s, 0.86), onSecondary: tone(c.s, 0.16),
            text: tone(c.n, 0.10), dim: tone(c.n, 0.32), outline: tone(c.n, 0.50),
            good: "#2e9b5f", warn: "#b7791f", bad: "#d64545"
        }
    }
    // the "Dark theme" tile: a preset swaps to Paper and back; a generated scheme flips its mode
    function setDark(on) {
        if (source === "preset") name = on ? lastDark : "paper"
        else darkMode = on
    }

    // Size of the whole island (views/Settings.qml): Bar scales every view by this, so all sizes
    // below are at 100 %. 0.8 .. 1.4.
    property real scale: 1.0

    // ---- Material roles ----
    readonly property color surface:     current.surface
    readonly property color container:   current.container
    readonly property color high:        current.high
    readonly property color highest:     current.highest
    readonly property color primary:     current.primary
    readonly property color primaryInk:  current.onPrimary
    readonly property color secondary:   current.secondary
    readonly property color secondaryInk: current.onSecondary
    readonly property color text:        current.text
    readonly property color dim:         current.dim
    readonly property color outline:     current.outline
    readonly property color good:        current.good
    readonly property color warn:        current.warn
    readonly property color bad:         current.bad
    readonly property bool  dark:        current.dark
    // a hairline between sections
    readonly property color divider:     mix(surface, outline, 0.35)
    // the icon circle on a primary tile: the primary, a shade deeper
    readonly property color primaryDeep: mix(primary, primaryInk, 0.16)

    // ---- the older names, still used by the workspace overview ----
    readonly property color raised:   container
    readonly property color hover:    high
    readonly property color selected: highest
    readonly property color track:    high
    readonly property color faint:    outline

    // a + (b - a) * t, per channel: Material's state layers and tonal blends
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }
    // the state layer: `base` under the pointer (8 %) or pressed/focused (12 %), tinted by `ink`
    function state(base, ink, hovered, pressed) {
        return pressed ? mix(base, ink, 0.12) : hovered ? mix(base, ink, 0.08) : base
    }

    // ---- shape (Material 3) ----
    // the island's largest corner; a shape lower than twice this is a capsule (the compact clock, HUDs)
    readonly property int radius: 28
    readonly property int cardRadius: 24       // cards inside the island (media, notifications)
    readonly property int innerRadius: 16      // rows, fields
    readonly property int smallRadius: 12      // thumbnails, album art

    // ---- the island's look (views/Settings.qml, IPC `style` / `handle`), remembered with the palette ----
    //   style   "pill":  floats below the top edge, every corner round
    //           "notch": flush with the top edge, square top, curving into the screen edge
    //   handle  auto-hide: what stays at the top edge while hidden: "strip" (a thin bar) or "none"
    property string style: "pill"
    property string handle: "strip"

    // Glass is Hyprland's (hypr/modules/look.lua): every window is drawn at decoration.active_opacity over
    // its blur, and layers named glass:* get the same blur. The island is one (Bar), so it takes
    // the windows' opacity, which shell.qml keeps in step with services/Desktops.qml.
    property real windowOpacity: 1
    readonly property color island: Qt.rgba(surface.r, surface.g, surface.b, Math.max(0, Math.min(1, windowOpacity)))

    // ---- motion ----
    // The island's morph spring (Bar). Anything inside a view that has to move with the island's
    // edge springs with it too (parts/WorkspaceButtons.qml). Higher stiffness = snappier; lower
    // damping = more overshoot.
    readonly property real stiffness: 3.2
    readonly property real damping: 0.34

    // the "Dark theme" tile: the dark palette to come back to from a light one
    property string lastDark: "teal"
    onNameChanged: if (palettes[name]?.dark) lastDark = name

    // Focus rings show only while the keyboard is being used (Material's "focus visible"): Bar sets
    // this when a key moves focus in a view and clears it when the pointer moves over the island.
    // True by default, so components used anywhere else always show them.
    property bool focusVisible: true

    // privacy dots beside the island (fixed: they mean the same thing in every palette)
    readonly property color microphone: "#ff9f1a"
    readonly property color camera: "#35ff72"
    readonly property color recording: "#ff5449"

    // One Material Symbols glyph per thing, used everywhere it appears (Tabs, the
    // dashboard, the launcher's actions, headers), so the same thing always looks the same.
    readonly property var symbol: ({
        back: "arrow_back", open: "arrow_forward", close: "close",
        hub: "apps", dashboard: "tune", launcher: "search", notifications: "notifications",
        overview: "grid_view", calendar: "calendar_month", media: "music_note", theme: "palette", settings: "settings",
        power: "power_settings_new", screenshot: "screenshot_region", record: "screen_record",
        dnd: "do_not_disturb_on", sound: "volume_up", muted: "volume_off", battery: "battery_full",
        mixer: "instant_mix"
    })

    // Fonts come from modules/features/theme.nix (inter, jetbrains-mono, material-symbols).
    readonly property string font: "Inter"
    readonly property string mono: "JetBrains Mono"
    readonly property string icons: "Material Symbols Rounded"

    // type scale: label, body, title, headline, display (a laptop at arm's length: on the big side)
    readonly property int small: 12
    readonly property int body: 14
    readonly property int large: 17
    readonly property int title: 22
    readonly property int headline: 30
    readonly property int display: 56

    // ~/.local/state/quickshell/island.ini. The config dir is a read-only Nix store path.
    property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini"
        category: "theme"
        property alias source: root.source
        property alias name: root.name
        property alias accent: root.accent
        property alias variant: root.variant
        property alias darkMode: root.darkMode
        property alias scale: root.scale
        property alias style: root.style
        property alias handle: root.handle
        property alias lastDark: root.lastDark
    }
}
