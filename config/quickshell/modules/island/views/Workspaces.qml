import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.island
import qs.modules.components
import qs.modules.services
import qs.modules.island.views.overview

// Workspace overview (ported from the old shell, after quickshell-overview): monitor-shaped
// tiles with live window previews, and a strip of special workspaces.
//   click a tile: go there          click a window: focus it      middle-click a window: close it
//   drag a window onto a tile, a special workspace, or "+" (a new special workspace): move it
//   arrows / hjkl: move between workspaces (live)   1-9, 0: jump   wheel: step through all of them
//   Enter: done (close)   Backspace: back   Escape: back (ViewLoader)
// Options and colours: overview/OverviewConfig.qml. Desktops reads hyprctl while this is open.
Item {
    id: root

    readonly property var cfg: OverviewConfig

    // ---- which monitor this island sits on ----
    readonly property var screen: QsWindow.window?.screen ?? null
    readonly property var monitor: (screen ? Hyprland.monitorFor(screen) : null) ?? Hyprland.focusedMonitor
    readonly property var monitorData: Desktops.monitorById(monitor?.id)

    // usable area of that monitor in logical px (what a window's `at`/`size` are measured in)
    readonly property real monitorScale: monitorData?.scale ?? monitor?.scale ?? 1
    readonly property bool rotated: (monitorData?.transform ?? 0) % 2 === 1
    readonly property var reserved: monitorData?.reserved ?? [0, 0, 0, 0]
    readonly property real physicalW: monitorData?.width ?? monitor?.width ?? 1920
    readonly property real physicalH: monitorData?.height ?? monitor?.height ?? 1080
    readonly property real usableW: Math.max(1, (rotated ? physicalH : physicalW) / monitorScale - reserved[0] - reserved[2])
    readonly property real usableH: Math.max(1, (rotated ? physicalW : physicalH) / monitorScale - reserved[1] - reserved[3])

    // ---- grid ----
    readonly property int rows: cfg.rows
    readonly property int columns: cfg.columns
    readonly property int workspacesShown: rows * columns
    readonly property int gap: cfg.workspaceSpacing
    readonly property int pad: cfg.padding

    // the configured scale, shrunk when the island wouldn't fit on the screen
    // Bar draws views at Config.scale, so at 100 % the screen is that much narrower
    readonly property real maxContentWidth: (screen?.width ?? usableW) * cfg.maxWidthFraction / Config.scale - pad * 2
    readonly property real previewScale: Math.max(0.02, Math.min(cfg.scale,
        (maxContentWidth - (columns - 1) * gap) / (columns * usableW)))
    readonly property real tileW: Math.round(usableW * previewScale)
    readonly property real tileH: Math.round(usableH * previewScale)
    readonly property real numberSize: cfg.workspaceNumberBaseSize * monitorScale * previewScale

    // ---- which workspaces show: the group of `workspacesShown` ids around the active one ----
    readonly property int workspaceOffset: cfg.useWorkspaceMap ? Number(cfg.workspaceMap[monitor?.id] ?? 0) : 0
    readonly property int activeWorkspaceId: Math.max(1, Math.min(100, monitor?.activeWorkspace?.id ?? Desktops.activeId))
    readonly property int workspaceGroup: Math.floor((activeWorkspaceId - workspaceOffset - 1) / workspacesShown)
    readonly property int minWorkspaceId: workspaceGroup * workspacesShown + 1 + workspaceOffset
    readonly property int maxWorkspaceId: minWorkspaceId + workspacesShown - 1

    // the wheel steps through every workspace, not only the visible group
    readonly property int stepMin: workspaceOffset + 1
    readonly property int stepMax: Math.max(stepMin + workspacesShown - 1, Desktops.highestId(stepMin), activeWorkspaceId)

    function toVisualRow(r)    { return cfg.orderBottomUp ? rows - r - 1 : r }
    function toVisualColumn(c) { return cfg.orderRightLeft ? columns - c - 1 : c }
    function rowOf(id)    { return toVisualRow(Math.floor((id - workspaceOffset - 1) / columns) % rows) }
    function columnOf(id) { return toVisualColumn((id - workspaceOffset - 1) % columns) }
    function workspaceInCell(r, c) { return minWorkspaceId + toVisualRow(r) * columns + toVisualColumn(c) }

    // rows with a window or the active workspace (empty rows are hidden when hideEmptyRows is on)
    readonly property var rowsWithContent: {
        if (!cfg.hideEmptyRows) return null
        const used = ({})
        if (activeWorkspaceId >= minWorkspaceId && activeWorkspaceId <= maxWorkspaceId) used[rowOf(activeWorkspaceId)] = true
        for (const win of Desktops.windowList) {
            const id = Number(win?.workspace?.id ?? -1)
            if (id >= minWorkspaceId && id <= maxWorkspaceId) used[rowOf(id)] = true
        }
        return used
    }
    readonly property int visibleRowCount: {
        if (!rowsWithContent) return rows
        let n = 0
        for (let i = 0; i < rows; i++) if (rowsWithContent[i]) n++
        return Math.max(1, n)
    }
    function rowVisible(r) { return !rowsWithContent || !!rowsWithContent[r] }
    function visibleRowPosition(r) {
        if (!rowsWithContent) return r
        let p = 0
        for (let i = 0; i < r; i++) if (rowsWithContent[i]) p++
        return p
    }

    readonly property var specialNames: cfg.showSpecialWorkspaces
        ? Desktops.specialWorkspaceNames(monitor?.name, monitor?.id, cfg.specialWorkspaces) : []

    readonly property real gridW: columns * tileW + (columns - 1) * gap
    readonly property real gridH: visibleRowCount * tileH + (visibleRowCount - 1) * gap
    readonly property real stripGap: gap * 2.8

    // a header with back, like every view
    readonly property real headerH: 52 + 12

    implicitWidth: content.width + pad * 2
    implicitHeight: content.height + headerH + pad * 2

    Component.onCompleted: Desktops.watch(true)
    Component.onDestruction: Desktops.watch(false)

    // ---- actions ----
    function selectWorkspace(id)  { Desktops.focus(id); Engine.close() }
    function selectWindow(address) { Desktops.focusWindow(address); Engine.close() }
    function toggleSpecial(name)  { Desktops.toggleSpecial(name); Engine.close() }
    function createSpecial()      { Desktops.toggleSpecial(Desktops.nextSpecialWorkspaceName(specialNames)); Engine.close() }

    // arrows / hjkl move around the grid, 1-9 and 0 jump to a position in the group
    function navigate(key) {
        const index = Math.max(0, Math.min(workspacesShown - 1, activeWorkspaceId - minWorkspaceId))
        let row = toVisualRow(Math.floor(index / columns))
        let column = toVisualColumn(index % columns)
        let target = -1

        if (key === Qt.Key_Left || key === Qt.Key_H)       column = (column - 1 + columns) % columns
        else if (key === Qt.Key_Right || key === Qt.Key_L) column = (column + 1) % columns
        else if (key === Qt.Key_Up || key === Qt.Key_K)    row = (row - 1 + rows) % rows
        else if (key === Qt.Key_Down || key === Qt.Key_J)  row = (row + 1) % rows
        else if (key >= Qt.Key_1 && key <= Qt.Key_9) {
            if (key - Qt.Key_0 > workspacesShown) return false
            target = minWorkspaceId + key - Qt.Key_1
        } else if (key === Qt.Key_0 && workspacesShown >= 10) target = minWorkspaceId + 9
        else return false

        if (target === -1) target = minWorkspaceId + toVisualRow(row) * columns + toVisualColumn(column)
        Desktops.focus(Math.max(minWorkspaceId, Math.min(maxWorkspaceId, target)))
        return true
    }

    // ---- the drag shared by every tile and preview ----
    QtObject {
        id: dragState

        readonly property string createTarget: "__create_special_workspace__"
        property int fromWorkspace: -1
        property int targetWorkspace: -1
        property string targetSpecial: ""
        property var specialNames: root.specialNames
        readonly property bool idle: targetWorkspace === -1 && targetSpecial === ""

        function reset() { fromWorkspace = -1; targetWorkspace = -1; targetSpecial = "" }
    }

    // ---- snapshot mode: previews re-capture when windows change ----
    property int recaptureToken: 0
    Connections {
        target: Hyprland
        enabled: root.cfg.eventPreviews
        function onRawEvent(event) {
            const name = String(event?.name ?? "")
            if (name === "openwindow" || name === "closewindow" || name === "movewindow") root.recaptureToken += 1
        }
    }

    // ---- keyboard: this view owns its keys; Escape still bubbles to ViewLoader ----
    Item {
        focus: true
        Keys.onPressed: event => {
            event.accepted = false                               // unhandled keys go on to ViewLoader
            if (event.key === Qt.Key_Escape) return              // ViewLoader: back
            Engine.key()
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { Engine.close(); event.accepted = true }
            else if (event.key === Qt.Key_Backspace) { Engine.back(); event.accepted = true }
            else if (root.navigate(event.key)) event.accepted = true
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const dy = event.angleDelta.y
            if (!dy) return
            Desktops.stepWorkspace(dy > 0 ? -1 : 1, root.stepMin, root.stepMax)
            event.accepted = true
        }
    }

    // clicks on the padding between tiles belong to the view, not to the island behind it
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: mouse => mouse.accepted = true
    }

    Header {
        x: root.pad
        y: root.pad
        width: content.width
        title: "Workspaces"
        subtitle: "Click to go · drag a window to move it · middle-click closes it"
        onBack: Engine.back()
    }

    Item {
        id: content

        x: root.pad
        y: root.pad + root.headerH
        width: root.gridW
        height: root.gridH + (strip.visible ? root.stripGap + strip.height : 0)

        // workspace tiles
        Item {
            width: root.gridW
            height: root.gridH

            Repeater {
                model: root.workspacesShown

                delegate: WorkspaceTile {
                    required property int index
                    readonly property int rowIndex: Math.floor(index / root.columns)
                    readonly property int colIndex: index % root.columns

                    visible: root.rowVisible(rowIndex)
                    x: colIndex * (root.tileW + root.gap)
                    y: root.visibleRowPosition(rowIndex) * (root.tileH + root.gap)
                    width: root.tileW
                    height: root.tileH
                    workspaceId: root.workspaceInCell(rowIndex, colIndex)
                    previewScale: root.previewScale
                    numberSize: root.numberSize
                    dnd: dragState

                    onActivated: id => root.selectWorkspace(id)
                }
            }
        }

        SpecialStrip {
            id: strip

            visible: root.cfg.showSpecialWorkspaces
            y: root.gridH + root.stripGap
            names: root.specialNames
            sectionWidth: root.gridW
            tileHeight: root.tileH
            fallbackTileWidth: root.tileW
            previewScale: root.previewScale
            spacing: root.gap
            monitorData: root.monitorData
            monitorId: root.monitor?.id ?? 0
            dnd: dragState
            tip: sharedTip
            dragLayer: floatLayer
            recaptureToken: root.recaptureToken

            onToggleRequested: name => root.toggleSpecial(name)
            onCreateRequested: root.createSpecial()
            onWindowActivated: address => root.selectWindow(address)
        }

        // The windows of the visible workspaces: one layer over the whole grid (not one per tile),
        // so a thumbnail can be dragged from any tile onto any other, or onto the special strip.
        Item {
            width: content.width
            height: content.height
            z: root.cfg.windowZ

            Repeater {
                model: ScriptModel { values: Toplevels.inRange(root.minWorkspaceId, root.maxWorkspaceId) }

                delegate: WindowPreview {
                    required property var modelData
                    required property int index
                    readonly property int tileColumn: root.columnOf(workspaceId)
                    readonly property int tileRow: root.visibleRowPosition(root.rowOf(workspaceId))

                    toplevel: modelData
                    dnd: dragState
                    tip: sharedTip
                    widgetMonitorData: root.monitorData
                    widgetMonitorId: root.monitor?.id ?? 0
                    previewScale: root.previewScale
                    availableWorkspaceWidth: root.tileW
                    availableWorkspaceHeight: root.tileH
                    xOffset: (root.tileW + root.gap) * tileColumn
                    yOffset: (root.tileH + root.gap) * tileRow
                    baseZ: root.cfg.windowZ + index
                    recaptureToken: root.recaptureToken

                    onActivated: address => root.selectWindow(address)
                }
            }

            // the focused workspace
            Rectangle {
                readonly property int column: root.columnOf(root.activeWorkspaceId)
                readonly property int row: root.visibleRowPosition(root.rowOf(root.activeWorkspaceId))

                visible: root.activeWorkspaceId >= root.minWorkspaceId && root.activeWorkspaceId <= root.maxWorkspaceId
                x: (root.tileW + root.gap) * column
                y: (root.tileH + root.gap) * row
                z: root.cfg.dragZ - 1
                width: root.tileW
                height: root.tileH
                color: "transparent"
                radius: Math.max(4, root.cfg.screenRounding * root.previewScale)
                border.width: 2
                border.color: root.cfg.colors.accent

                Behavior on x { NumberAnimation { duration: root.cfg.moveFastMs; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: root.cfg.moveFastMs; easing.type: Easing.OutCubic } }
            }
        }
    }

    // thumbnails dragged out of a special tile live here (the tile clips them)
    Item {
        id: floatLayer
        anchors.fill: parent
        z: root.cfg.dragZ + 1
    }

    WindowTip {
        id: sharedTip
        z: root.cfg.dragZ + 2
    }
}
