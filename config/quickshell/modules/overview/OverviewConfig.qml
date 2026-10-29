pragma Singleton

import QtQuick
import Quickshell
import qs.modules.components

// Options for the Workspaces overview (ported from the old shell, after quickshell-overview;
// names follow its config.json). Colours come from the island's palette (Config).
Singleton {
    id: root

    // ---- grid ----
    property int rows: 2
    property int columns: 5
    property real scale: 0.16                 // upper bound: shrinks automatically to fit the screen
    property real maxWidthFraction: 0.92      // share of the screen width the island may take
    property bool hideEmptyRows: true
    property bool orderRightLeft: false
    property bool orderBottomUp: false
    property bool useWorkspaceMap: false      // per-monitor workspace offset (workspaceMap[monitorId])
    property var workspaceMap: [0, 10]
    property int workspaceSpacing: 5
    property int padding: 12
    property real workspaceNumberBaseSize: 250

    // ---- previews ----
    property bool previewsEnabled: true
    property string previewMode: "live"       // "live" | "event" (a snapshot, re-captured on window events)
    property bool includeInactiveMonitorPreviews: true
    property int previewRecaptureDelayMs: 60
    readonly property bool livePreviews: previewsEnabled && previewMode !== "event"
    readonly property bool eventPreviews: previewsEnabled && previewMode === "event"

    // ---- special workspaces ----
    property bool showSpecialWorkspaces: true
    property var specialWorkspaces: []        // always listed, even while empty
    property int specialWorkspaceColumns: 5

    // ---- wallpapers for the (empty) tiles; "" = plain tiles with a big number ----
    property string emptyWorkspaceWallpaper: ""
    property string specialEmptyWorkspaceWallpaper: ""

    // ---- window previews ----
    property bool showIcons: true
    property real iconToWindowRatio: 0.25
    property real iconToWindowRatioCompact: 0.45
    property int compactThreshold: 48         // px; below this the icon gets the compact ratio
    property real inactiveMonitorOpacity: 0.4
    property bool cropToFill: false

    // ---- opacity ----
    property real workspaceOpacity: 0.86
    property real emptyWallpaperOverlayOpacity: 0.18
    property real windowOverlayOpacity: 0.22

    // ---- shape / type / motion (reference sizes, scaled by `scale` where they're used) ----
    property real screenRounding: 23
    property real windowRounding: 18
    property real normalRounding: 17
    property int fontSmall: 15
    property int moveFastMs: 200
    property int moveEnterMs: 400

    // ---- stacking ----
    readonly property int windowZ: 1
    readonly property int dragZ: 99999

    // ---- races ----
    property int raceDelayMs: 150             // wait for hyprctl to report a finished move before snapping back

    readonly property QtObject colors: QtObject {
        readonly property color tile: Config.raised
        readonly property color tileHover: Config.hover
        readonly property color tileHoverBorder: Config.primary
        readonly property color number: Config.text
        readonly property color accent: Config.primary
        readonly property color window: Config.raised
        readonly property color windowHover: Config.hover
        readonly property color windowActive: Config.selected
        readonly property color windowOutline: Config.faint
        readonly property color strip: Config.surface
        readonly property color stripBorder: Config.track
        readonly property color stripTile: Config.raised
        readonly property color createTile: Config.raised
        readonly property color text: Config.text
        readonly property color textDim: Config.dim
        readonly property color tooltip: Config.text
        readonly property color tooltipText: Config.surface
    }

    function wallpaperUrl(path) {
        const p = String(path ?? "").trim()
        if (p.length === 0) return ""
        if (/^(file:|qrc:|image:|https?:)/.test(p)) return p
        return p.startsWith("/") ? "file://" + p : p
    }
}
