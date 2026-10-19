import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.taskbar


import qs.modules.services
import qs.modules.taskbar.views.workspaces

// Workspace overview, after quickshell-overview: a grid of monitor-shaped tiles with live window
// previews, drag & drop between workspaces, and a strip of special workspaces.
//
// Island contract (see Island.qml): implicitWidth/Height drive the morph, closeRequested() asks to close.
// Registry marks this view `keys: true`, so it owns the keyboard the moment it opens.
FocusScope {
    id: root

    signal closeRequested()

    readonly property var cfg: OverviewConfig

    // ---- which monitor this island sits on ----
    readonly property var screen: QsWindow.window?.screen ?? null
    readonly property var monitor: (screen ? Hyprland.monitorFor(screen) : null) ?? Hyprland.focusedMonitor
    readonly property var monitorData: Workspaces.monitorById(monitor?.id)

    // Usable area of that monitor in logical px (what a window's `at`/`size` are measured in).
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

    // Configured scale, shrunk when the island would not fit on the screen.
    readonly property real maxContentWidth: (screen?.width ?? usableW) * cfg.maxWidthFraction - pad * 2
    readonly property real previewScale: Math.max(0.02, Math.min(cfg.scale,
        (maxContentWidth - (columns - 1) * gap) / (columns * usableW)))
    readonly property real tileW: Math.round(usableW * previewScale)
    readonly property real tileH: Math.round(usableH * previewScale)
    readonly property real numberSize: cfg.workspaceNumberBaseSize * monitorScale * previewScale

    // ---- which workspaces are shown: the group of `workspacesShown` ids around the active one ----
    readonly property int workspaceOffset: cfg.useWorkspaceMap ? Number(cfg.workspaceMap[monitor?.id] ?? 0) : 0
    readonly property int activeWorkspaceId: Math.max(1, Math.min(100, monitor?.activeWorkspace?.id ?? Workspaces.activeId))
    readonly property int workspaceGroup: Math.floor((activeWorkspaceId - workspaceOffset - 1) / workspacesShown)
    readonly property int minWorkspaceId: workspaceGroup * workspacesShown + 1 + workspaceOffset
    readonly property int maxWorkspaceId: minWorkspaceId + workspacesShown - 1

    // Wheel steps through every workspace, not only the visible group.
    readonly property int stepMin: workspaceOffset + 1
    readonly property int stepMax: Math.max(stepMin + workspacesShown - 1, Workspaces.highestId(stepMin), activeWorkspaceId)

    function toVisualRow(normalRow)       { return cfg.orderBottomUp ? rows - normalRow - 1 : normalRow }
    function toVisualColumn(normalColumn) { return cfg.orderRightLeft ? columns - normalColumn - 1 : normalColumn }

    function rowOf(workspaceId) {
        const normal = Math.floor((workspaceId - workspaceOffset - 1) / columns) % rows
        return toVisualRow(normal)
    }
    function columnOf(workspaceId) {
        return toVisualColumn((workspaceId - workspaceOffset - 1) % columns)
    }
    function workspaceInCell(rowIndex, colIndex) {
        return minWorkspaceId + toVisualRow(rowIndex) * columns + toVisualColumn(colIndex)
    }

    // Rows that have a window or the active workspace (empty rows are hidden when hideEmptyRows is on).
    readonly property var rowsWithContent: {
        if (!cfg.hideEmptyRows) return null
        const used = ({})
        if (activeWorkspaceId >= minWorkspaceId && activeWorkspaceId <= maxWorkspaceId)
            used[rowOf(activeWorkspaceId)] = true
        for (let i = 0; i < Workspaces.windowList.length; i++) {
            const id = Number(Workspaces.windowList[i]?.workspace?.id ?? -1)
            if (id >= minWorkspaceId && id <= maxWorkspaceId) used[rowOf(id)] = true
        }
        return used
    }
    readonly property int visibleRowCount: {
        if (!rowsWithContent) return rows
        let count = 0
        for (let i = 0; i < rows; i++) if (rowsWithContent[i]) count++
        return Math.max(1, count)
    }
    function rowVisible(rowIndex) { return !rowsWithContent || !!rowsWithContent[rowIndex] }
    function visibleRowPosition(rowIndex) {
        if (!rowsWithContent) return rowIndex
        let position = 0
        for (let i = 0; i < rowIndex; i++) if (rowsWithContent[i]) position++
        return position
    }

    // ---- special workspaces ----
    readonly property var specialNames: cfg.showSpecialWorkspaces
        ? Workspaces.specialWorkspaceNames(monitor?.name, monitor?.id, cfg.specialWorkspaces)
        : []

    // ---- content geometry ----
    readonly property real gridW: columns * tileW + (columns - 1) * gap
    readonly property real gridH: visibleRowCount * tileH + (visibleRowCount - 1) * gap
    readonly property real stripGap: gap * 1.8 + gap

    implicitWidth: content.width + pad * 2
    implicitHeight: content.height + pad * 2

    // ---- actions ----
    function selectWorkspace(workspaceId) {
        Workspaces.focus(workspaceId)
        closeRequested()
    }
    function selectWindow(address) {
        Workspaces.focusWindow(address)
        closeRequested()
    }
    function toggleSpecial(name) {
        Workspaces.toggleSpecial(name)
        closeRequested()
    }
    function createSpecial() {
        Workspaces.toggleSpecial(Workspaces.nextSpecialWorkspaceName(specialNames))
        closeRequested()
    }

    // arrows / hjkl move the focus around the grid, 1-9 and 0 jump to a position in the group
    function navigate(key) {
        const index = Math.max(0, Math.min(workspacesShown - 1, activeWorkspaceId - minWorkspaceId))
        let row = toVisualRow(Math.floor(index / columns))
        let column = toVisualColumn(index % columns)
        let targetId = -1

        if (key === Qt.Key_Left || key === Qt.Key_H)       column = (column - 1 + columns) % columns
        else if (key === Qt.Key_Right || key === Qt.Key_L) column = (column + 1) % columns
        else if (key === Qt.Key_Up || key === Qt.Key_K)    row = (row - 1 + rows) % rows
        else if (key === Qt.Key_Down || key === Qt.Key_J)  row = (row + 1) % rows
        else if (key >= Qt.Key_1 && key <= Qt.Key_9) {
            const position = key - Qt.Key_0
            if (position > workspacesShown) return false
            targetId = minWorkspaceId + position - 1
        } else if (key === Qt.Key_0 && workspacesShown >= 10) {
            targetId = minWorkspaceId + 9
        } else {
            return false
        }

        if (targetId === -1)
            targetId = minWorkspaceId + toVisualRow(row) * columns + toVisualColumn(column)

        Workspaces.focus(Math.max(minWorkspaceId, Math.min(maxWorkspaceId, targetId)))
        return true
    }

    // ---- shared drag state (read by tiles, written by window previews) ----
    QtObject {
        id: dragState

        readonly property string createTarget: "__create_special_workspace__"
        property int fromWorkspace: -1
        property int targetWorkspace: -1
        property string targetSpecial: ""
        property var specialNames: root.specialNames
        readonly property bool idle: targetWorkspace === -1 && targetSpecial === ""

        function reset() {
            fromWorkspace = -1
            targetWorkspace = -1
            targetSpecial = ""
        }
    }

    // ---- snapshot mode: ask previews to re-capture when windows change ----
    property int recaptureToken: 0

    Connections {
        target: Hyprland
        enabled: root.cfg.eventPreviews

        function onRawEvent(event) {
            const name = String(event?.name ?? event?.event ?? event?.type ?? "")
            if (name === "openwindow" || name === "closewindow" || name === "movewindow")
                root.recaptureToken += 1
        }
    }

    // ---- input ----
    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.closeRequested()
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            IslandState.send(IslandState.Event.Back)
            event.accepted = true
        } else if (root.navigate(event.key)) {
            event.accepted = true
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const dy = event.angleDelta.y
            if (!dy) return
            Workspaces.stepWorkspace(dy > 0 ? -1 : 1, root.stepMin, root.stepMax)
            event.accepted = true
        }
    }

    // Clicks on the padding between tiles belong to the view; only a click *outside* the island closes it.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: mouse => mouse.accepted = true
    }

    // ---- content ----
    Item {
        id: content

        x: root.pad
        y: root.pad
        width: root.gridW
        height: root.gridH + (strip.visible ? root.stripGap + strip.height : 0)

        // workspace tiles
        Item {
            id: grid
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

                    onActivated: wsId => root.selectWorkspace(wsId)
                }
            }
        }

        // special workspaces
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

        // Windows of the visible workspaces. One layer over the whole grid (not one per tile) so a
        // thumbnail can be dragged from any tile onto any other, or onto the special strip.
        Item {
            id: windowSpace
            width: content.width
            height: content.height
            z: root.cfg.windowZ

            Repeater {
                model: ScriptModel {
                    values: Toplevels.inRange(root.minWorkspaceId, root.maxWorkspaceId)
                }

                delegate: WindowPreview {
                    id: win
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

            // focused workspace
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

    // Thumbnails dragged out of a special tile live here (its container clips them).
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