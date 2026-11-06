pragma Singleton

import QtQuick
import Quickshell
import qs.modules.components

// Names follow quickshell-overview's config.json, where this was ported from.
Singleton {
    id: root

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

    property bool previewsEnabled: true
    property string previewMode: "live"       // "live" | "event" (a snapshot, re-captured on window events)
    property bool includeInactiveMonitorPreviews: true
    property int previewRecaptureDelayMs: 60
    readonly property bool livePreviews: previewsEnabled && previewMode !== "event"
    readonly property bool eventPreviews: previewsEnabled && previewMode === "event"

    property bool showSpecialWorkspaces: true
    property var specialWorkspaces: []        // always listed, even while empty
    property int specialWorkspaceColumns: 5

    // "" = plain tiles with a big number
    property string emptyWorkspaceWallpaper: ""
    property string specialEmptyWorkspaceWallpaper: ""

    property bool showIcons: true
    property real iconToWindowRatio: 0.25
    property real iconToWindowRatioCompact: 0.45
    property int compactThreshold: 48         // px; below this the icon gets the compact ratio
    property real inactiveMonitorOpacity: 0.4
    property bool cropToFill: false

    property real workspaceOpacity: 0.86
    property real emptyWallpaperOverlayOpacity: 0.18
    property real windowOverlayOpacity: 0.22

    // reference sizes, scaled by `scale` where they're used
    property real screenRounding: 23
    property real windowRounding: 18
    property real normalRounding: 17
    property int fontSmall: 15
    property int moveFastMs: 200
    property int moveEnterMs: 400

    readonly property int windowZ: 1
    readonly property int dragZ: 99999

    property int raceDelayMs: 150             // wait for hyprctl to report a finished move before snapping back

    readonly property QtObject colors: QtObject {
        readonly property color tile: Config.container
        readonly property color tileHover: Config.high
        readonly property color tileHoverBorder: Config.primary
        readonly property color number: Config.text
        readonly property color accent: Config.primary
        readonly property color window: Config.container
        readonly property color windowHover: Config.high
        readonly property color windowActive: Config.highest
        readonly property color windowOutline: Config.outline
        readonly property color strip: Config.surface
        readonly property color stripBorder: Config.high
        readonly property color stripTile: Config.container
        readonly property color createTile: Config.container
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
