pragma Singleton

import QtQuick
import Quickshell

// Options + palette for the Workspaces view. Names follow quickshell-overview's config.json
// ("overview", "windowPreview", "hacks") so the two stay easy to compare. Plain properties for now;
// bind them to a settings file later without touching the view.
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
    property string previewMode: "live"       // "live" | "event" (snapshot, re-captured on window events)
    property bool includeInactiveMonitorPreviews: true
    property int previewRecaptureDelayMs: 60
    readonly property string normalizedPreviewMode: {
        const mode = String(previewMode ?? "live").trim().toLowerCase()
        return (mode === "event" || mode === "snapshot") ? "event" : "live"
    }
    readonly property bool livePreviews: previewsEnabled && normalizedPreviewMode === "live"
    readonly property bool eventPreviews: previewsEnabled && normalizedPreviewMode === "event"

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

    // ---- shape / type / motion (reference defaults, scaled by `scale` at the call site) ----
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

    // ---- palette (tuned for the black island body) ----
    readonly property QtObject colors: QtObject {
        readonly property color tile: "#151515"
        readonly property color tileHover: "#1f252f"
        readonly property color tileHoverBorder: "#5c6f89"
        readonly property color number: "#f7f7f7"
        readonly property color accent: "#70a7ff"
        readonly property color window: "#1e1e1e"
        readonly property color windowHover: "#2c2c2c"
        readonly property color windowActive: "#383838"
        readonly property color windowOutline: "#808080"
        readonly property color strip: "#101010"
        readonly property color stripBorder: "#2a2a2a"
        readonly property color stripTile: "#171717"
        readonly property color createTile: "#1a2029"
        readonly property color text: "#f7f7f7"
        readonly property color textDim: "#dcdcdc"
        readonly property color tooltip: "#ececec"
        readonly property color tooltipText: "#222222"
    }

    function wallpaperUrl(path) {
        const p = String(path ?? "").trim()
        if (p.length === 0) return ""
        if (/^(file:|qrc:|image:|https?:)/.test(p)) return p
        return p.startsWith("/") ? "file://" + p : p
    }
}