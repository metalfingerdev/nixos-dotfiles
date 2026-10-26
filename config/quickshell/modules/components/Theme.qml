pragma Singleton

import QtQuick
import QtCore

// Colours, radius and type for the whole island. Bar, the components and every view read these;
// nothing else hard-codes a colour. `name` picks a palette (views/ThemePicker.qml, IPC `theme`)
// and is remembered across restarts.
//
// Plain QtQuick + QtCore (no Quickshell), so modules/tests/tst_keyboard.qml can still load Pill.
QtObject {
    id: root

    // Every palette has the same keys:
    //   surface   the island itself            raised    pills, cards, fields
    //   hover     raised, under the pointer    selected  raised, keyboard focus
    //   track     empty part of bars/switches  text      primary text
    //   dim       secondary text               faint     placeholders, borders
    //   accent    on / current / connected     good, warn, bad   status
    readonly property var palettes: ({
        graphite: { label: "Graphite", surface: "#101014", raised: "#1a1a1a", hover: "#2e2e2e", selected: "#3a3a3f",
                    track: "#2a2a2a", text: "#f7f7f7", dim: "#9a9a9a", faint: "#6a6a72",
                    accent: "#8ab4ff", good: "#7ee2a8", warn: "#ffcc66", bad: "#ff6b6b" },
        midnight: { label: "Midnight", surface: "#0b0f1a", raised: "#151b2b", hover: "#202840", selected: "#2a3452",
                    track: "#1e2638", text: "#e8ecf7", dim: "#8f9ab5", faint: "#5a6585",
                    accent: "#7aa2f7", good: "#9ece6a", warn: "#e0af68", bad: "#f7768e" },
        nord:     { label: "Nord", surface: "#2e3440", raised: "#3b4252", hover: "#434c5e", selected: "#4c566a",
                    track: "#434c5e", text: "#eceff4", dim: "#aeb7c8", faint: "#7b879c",
                    accent: "#88c0d0", good: "#a3be8c", warn: "#ebcb8b", bad: "#bf616a" },
        rose:     { label: "Rosé", surface: "#191724", raised: "#1f1d2e", hover: "#26233a", selected: "#393552",
                    track: "#2a273f", text: "#e0def4", dim: "#908caa", faint: "#6e6a86",
                    accent: "#ebbcba", good: "#9ccfd8", warn: "#f6c177", bad: "#eb6f92" },
        forest:   { label: "Forest", surface: "#11150f", raised: "#1b2118", hover: "#262e22", selected: "#323c2d",
                    track: "#252c21", text: "#e6eadf", dim: "#9aa592", faint: "#69745f",
                    accent: "#a7c080", good: "#83c092", warn: "#dbbc7f", bad: "#e67e80" },
        paper:    { label: "Paper", surface: "#f4f4f1", raised: "#e6e6e2", hover: "#d9d9d4", selected: "#cbcbc5",
                    track: "#d4d4cf", text: "#1c1c1e", dim: "#5e5e63", faint: "#8e8e93",
                    accent: "#2f6fde", good: "#2e9b5f", warn: "#b7791f", bad: "#d64545" }
    })
    readonly property var names: Object.keys(palettes)

    property string name: "graphite"
    readonly property var current: palettes[name] ?? palettes.graphite

    readonly property color surface:  current.surface
    readonly property color raised:   current.raised
    readonly property color hover:    current.hover
    readonly property color selected: current.selected
    readonly property color track:    current.track
    readonly property color text:     current.text
    readonly property color dim:      current.dim
    readonly property color faint:    current.faint
    readonly property color accent:   current.accent
    readonly property color good:     current.good
    readonly property color warn:     current.warn
    readonly property color bad:      current.bad

    readonly property int radius: 12          // the island
    readonly property int innerRadius: 8      // cards, rows and fields inside it

    // Fonts come from modules/features/theme.nix (inter, maple-mono.NF, material-symbols).
    readonly property string font: "Inter"
    readonly property string mono: "Maple Mono NF"
    readonly property string icons: "Material Symbols Rounded"

    readonly property int small: 11
    readonly property int body: 13
    readonly property int large: 16
    readonly property int display: 44

    // ~/.local/state/quickshell/island.ini. The config dir is a read-only Nix store path.
    property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini"
        category: "theme"
        property alias name: root.name
    }
}
