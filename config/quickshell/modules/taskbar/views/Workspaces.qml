import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.taskbar

FocusScope {
    id: root

    readonly property int rows: 2
    readonly property int columns: 5
    readonly property bool hideEmptyRows: true
    readonly property bool orderRightLeft: false
    readonly property bool orderBottomUp: false

    readonly property int workspacesShown: rows * columns
    readonly property int workspaceOffset: 0
    readonly property int activeWorkspaceId: Math.max(1, Workspaces.activeId > 0 ? Workspaces.activeId : 1)
    readonly property int workspaceGroup: Math.floor((activeWorkspaceId - workspaceOffset - 1) / workspacesShown)
    readonly property int minWorkspaceId: workspaceGroup * workspacesShown + 1 + workspaceOffset
    readonly property int maxWorkspaceId: minWorkspaceId + workspacesShown - 1

    readonly property int headerH: 44
    readonly property int spacing: 8
    readonly property int cellW: 98
    readonly property int cellH: 62
    readonly property int specialCellW: 98
    readonly property int specialCellH: 46

    property int draggingTargetWorkspace: -1
    property string draggingTargetSpecialWorkspace: ""
    readonly property string createSpecialWorkspaceTarget: "__create_special_workspace__"

    readonly property var monitorSpecialWorkspaceNames: {
        const out = []
        const seen = ({})
        for (let i = 0; i < Workspaces.allWorkspaces.length; i++) {
            const ws = Workspaces.allWorkspaces[i]
            const name = String(ws?.name ?? "")
            if (!name.startsWith("special:")) continue
            const special = name.slice(8)
            if (special.length === 0 || seen[special]) continue
            seen[special] = true
            out.push(special)
        }
        return out
    }

    readonly property var specialWorkspaceNamesFromWindows: {
        const out = []
        const seen = ({})
        for (let i = 0; i < Workspaces.windowList.length; i++) {
            const name = Workspaces.specialWorkspaceName(Workspaces.windowList[i])
            if (name.length === 0 || seen[name]) continue
            seen[name] = true
            out.push(name)
        }
        return out
    }

    readonly property var visibleSpecialWorkspaces: {
        const out = []
        const seen = ({})
        for (let i = 0; i < monitorSpecialWorkspaceNames.length; i++) {
            const n1 = String(monitorSpecialWorkspaceNames[i] || "").trim()
            if (n1.length > 0 && !seen[n1]) { seen[n1] = true; out.push(n1) }
        }
        for (let j = 0; j < specialWorkspaceNamesFromWindows.length; j++) {
            const n2 = String(specialWorkspaceNamesFromWindows[j] || "").trim()
            if (n2.length > 0 && !seen[n2]) { seen[n2] = true; out.push(n2) }
        }
        return out
    }

    readonly property var rowsWithContent: {
        if (!hideEmptyRows) return null
        const used = ({})
        used[getWorkspaceRow(activeWorkspaceId)] = true
        for (let i = 0; i < Workspaces.windowList.length; i++) {
            const win = Workspaces.windowList[i]
            const wsId = Number(win?.workspace?.id ?? -1)
            if (!Number.isFinite(wsId)) continue
            if (wsId < minWorkspaceId || wsId > maxWorkspaceId) continue
            used[getWorkspaceRow(wsId)] = true
        }
        return used
    }

    readonly property int visibleRowCount: {
        if (!hideEmptyRows || !rowsWithContent) return rows
        let c = 0
        for (let i = 0; i < rows; i++) if (rowsWithContent[i]) c++
        return Math.max(1, c)
    }

    function toVisualRow(normalRow) {
        return orderBottomUp ? (rows - normalRow - 1) : normalRow
    }

    function toVisualColumn(normalColumn) {
        return orderRightLeft ? (columns - normalColumn - 1) : normalColumn
    }

    function toNormalRow(visualRow) {
        return orderBottomUp ? (rows - visualRow - 1) : visualRow
    }

    function toNormalColumn(visualColumn) {
        return orderRightLeft ? (columns - visualColumn - 1) : visualColumn
    }

    function getWorkspaceRow(workspaceId) {
        const adjusted = workspaceId - workspaceOffset
        const normal = Math.floor((adjusted - 1) / columns) % rows
        return orderBottomUp ? (rows - normal - 1) : normal
    }

    function getWorkspaceColumn(workspaceId) {
        const adjusted = workspaceId - workspaceOffset
        const normal = (adjusted - 1) % columns
        return orderRightLeft ? (columns - normal - 1) : normal
    }

    function getWorkspaceInCell(rowIndex, colIndex) {
        const mappedRow = orderBottomUp ? (rows - rowIndex - 1) : rowIndex
        const mappedCol = orderRightLeft ? (columns - colIndex - 1) : colIndex
        return workspaceGroup * workspacesShown + mappedRow * columns + mappedCol + 1 + workspaceOffset
    }

    function getVisibleRowPosition(rowIndex) {
        if (!hideEmptyRows || !rowsWithContent) return rowIndex
        let visibleRow = 0
        for (let i = 0; i < rowIndex; i++) if (rowsWithContent[i]) visibleRow++
        return visibleRow
    }

    function workspaceHasWindows(workspaceId) {
        for (let i = 0; i < Workspaces.windowList.length; i++) {
            const wsId = Number(Workspaces.windowList[i]?.workspace?.id ?? -1)
            if (wsId === workspaceId && Workspaces.specialWorkspaceName(Workspaces.windowList[i]) === "") return true
        }
        return false
    }

    function selectWorkspace(workspaceId) {
        Workspaces.focus(workspaceId)
        IslandState.send(IslandState.Event.Close)
    }

    function selectWindow(address) {
        Workspaces.focusWindow(address)
        IslandState.send(IslandState.Event.Close)
    }

    function handleGridNavigation(key) {
        const clampedIndex = Math.max(0, Math.min(workspacesShown - 1, activeWorkspaceId - minWorkspaceId))
        const currentNormalRow = Math.floor(clampedIndex / columns)
        const currentNormalColumn = clampedIndex % columns

        let targetVisualRow = toVisualRow(currentNormalRow)
        let targetVisualColumn = toVisualColumn(currentNormalColumn)
        let targetId = -1

        if (key === Qt.Key_Left || key === Qt.Key_H) targetVisualColumn = (targetVisualColumn - 1 + columns) % columns
        else if (key === Qt.Key_Right || key === Qt.Key_L) targetVisualColumn = (targetVisualColumn + 1) % columns
        else if (key === Qt.Key_Up || key === Qt.Key_K) targetVisualRow = (targetVisualRow - 1 + rows) % rows
        else if (key === Qt.Key_Down || key === Qt.Key_J) targetVisualRow = (targetVisualRow + 1) % rows
        else if (key >= Qt.Key_1 && key <= Qt.Key_9) {
            const position = key - Qt.Key_0
            if (position <= workspacesShown) targetId = minWorkspaceId + position - 1
        } else if (key === Qt.Key_0 && workspacesShown >= 10) {
            targetId = minWorkspaceId + 9
        } else {
            return false
        }

        if (targetId === -1) {
            const targetNormalRow = toNormalRow(targetVisualRow)
            const targetNormalColumn = toNormalColumn(targetVisualColumn)
            targetId = minWorkspaceId + targetNormalRow * columns + targetNormalColumn
        }

        const clampedTarget = Math.max(minWorkspaceId, Math.min(maxWorkspaceId, targetId))
        Workspaces.focus(clampedTarget)
        return true
    }

    implicitWidth: 560
    implicitHeight: headerH + visibleRowCount * cellH + Math.max(0, visibleRowCount - 1) * spacing + (visibleSpecialWorkspaces.length > 0 ? (spacing + specialCellH) : 0) + 28

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            IslandState.send(IslandState.Event.Close)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backspace) {
            IslandState.send(IslandState.Event.Back)
            event.accepted = true
            return
        }
        if (handleGridNavigation(event.key)) {
            event.accepted = true
            return
        }
    }

    WheelHandler {
        onWheel: event => {
            const dy = event.angleDelta.y
            if (!dy) return
            Workspaces.stepWorkspace(dy > 0 ? -1 : 1, minWorkspaceId, maxWorkspaceId)
            event.accepted = true
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: root.spacing

        Item {
            width: parent.width
            height: root.headerH

            Text {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Workspaces"
                color: "#f7f7f7"
                font.pixelSize: 14
                font.bold: true
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Pill { text: "prev"; onClicked: Workspaces.stepWorkspace(-1, minWorkspaceId, maxWorkspaceId) }
                Pill { text: "next"; onClicked: Workspaces.stepWorkspace(1, minWorkspaceId, maxWorkspaceId) }
                Pill { text: "back"; onClicked: IslandState.send(IslandState.openHome()) }
            }
        }

        Rectangle {
            id: gridBox
            width: parent.width
            height: visibleRowCount * cellH + Math.max(0, visibleRowCount - 1) * root.spacing
            radius: 12
            color: "#131313"
            border.width: 1
            border.color: "#2a2a2a"

            Grid {
                id: workspaceGrid
                anchors.centerIn: parent
                rows: root.rows
                columns: root.columns
                rowSpacing: root.spacing
                columnSpacing: root.spacing

                Repeater {
                    model: root.rows * root.columns
                    delegate: Rectangle {
                        required property int index
                        readonly property int rowIndex: Math.floor(index / root.columns)
                        readonly property int colIndex: index % root.columns
                        readonly property int workspaceValue: root.getWorkspaceInCell(rowIndex, colIndex)
                        readonly property bool visibleRow: !root.hideEmptyRows || !!root.rowsWithContent[rowIndex]
                        readonly property bool active: workspaceValue === Workspaces.activeId
                        readonly property bool hasWindows: root.workspaceHasWindows(workspaceValue)
                        property bool hoveredWhileDragging: false

                        width: root.cellW
                        height: visibleRow ? root.cellH : 0
                        visible: visibleRow
                        radius: 10
                        color: active ? "#1d3b5d" : (hoveredWhileDragging ? "#1f252f" : "#101010")
                        border.width: active ? 2 : 1
                        border.color: active ? "#70a7ff" : (hoveredWhileDragging ? "#5c6f89" : "#2a2a2a")

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: root.selectWorkspace(parent.workspaceValue)
                        }

                        DropArea {
                            anchors.fill: parent
                            onEntered: {
                                root.draggingTargetSpecialWorkspace = ""
                                root.draggingTargetWorkspace = parent.workspaceValue
                                parent.hoveredWhileDragging = true
                            }
                            onExited: {
                                if (root.draggingTargetWorkspace === parent.workspaceValue)
                                    root.draggingTargetWorkspace = -1
                                parent.hoveredWhileDragging = false
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            text: parent.workspaceValue
                            color: "#f7f7f7"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            text: hasWindows ? "active" : "empty"
                            color: hasWindows ? "#9bd18f" : "#808080"
                            font.pixelSize: 10
                        }

                        Repeater {
                            model: Workspaces.windowList.filter(w => {
                                if (Workspaces.specialWorkspaceName(w) !== "") return false
                                return Number(w?.workspace?.id ?? -1) === parent.workspaceValue
                            })
                            delegate: Rectangle {
                                required property var modelData
                                readonly property string address: String(modelData?.address ?? "")
                                readonly property int monitorId: Number(modelData?.monitor ?? -1)
                                readonly property var monitor: Workspaces.monitors.find(m => m.id === monitorId)
                                readonly property real posBaseX: Number(monitor?.x ?? 0) + Number(monitor?.reserved?.[0] ?? 0)
                                readonly property real posBaseY: Number(monitor?.y ?? 0) + Number(monitor?.reserved?.[1] ?? 0)
                                readonly property real monW: Math.max(1, Number(monitor?.width ?? 1))
                                readonly property real monH: Math.max(1, Number(monitor?.height ?? 1))
                                readonly property real wx: Number(modelData?.at?.[0] ?? 0)
                                readonly property real wy: Number(modelData?.at?.[1] ?? 0)
                                readonly property real ww: Number(modelData?.size?.[0] ?? 120)
                                readonly property real wh: Number(modelData?.size?.[1] ?? 80)
                                readonly property real scaleX: parent.width / monW
                                readonly property real scaleY: parent.height / monH

                                x: Math.max(2, Math.min(parent.width - width - 2, (wx - posBaseX) * scaleX))
                                y: Math.max(18, Math.min(parent.height - height - 2, (wy - posBaseY) * scaleY))
                                width: Math.max(16, Math.min(parent.width - 4, ww * scaleX))
                                height: Math.max(12, Math.min(parent.height - 20, wh * scaleY))
                                radius: 6
                                color: "#2a2a2a"
                                border.width: 1
                                border.color: "#4a4a4a"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 8
                                    text: String(modelData?.class ?? "window")
                                    elide: Text.ElideRight
                                    color: "#dcdcdc"
                                    font.pixelSize: 9
                                }

                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    drag.target: parent
                                    hoverEnabled: true
                                    onPressed: {
                                        parent.z = 10000
                                        root.draggingTargetSpecialWorkspace = ""
                                        root.draggingTargetWorkspace = -1
                                    }
                                    onReleased: {
                                        const targetWorkspace = root.draggingTargetWorkspace
                                        const targetSpecial = root.draggingTargetSpecialWorkspace
                                        parent.z = 0

                                        if (targetSpecial === root.createSpecialWorkspaceTarget) {
                                            const created = Workspaces.nextSpecialWorkspaceName(root.visibleSpecialWorkspaces)
                                            Workspaces.moveWindowToSpecial(parent.address, created)
                                        } else if (targetSpecial.length > 0) {
                                            Workspaces.moveWindowToSpecial(parent.address, targetSpecial)
                                        } else if (targetWorkspace > 0 && targetWorkspace !== parent.workspaceValue) {
                                            Workspaces.moveWindowToWorkspace(parent.address, targetWorkspace)
                                        }

                                        root.draggingTargetSpecialWorkspace = ""
                                        root.draggingTargetWorkspace = -1
                                        parent.x = Qt.binding(function() { return Math.max(2, Math.min(parent.parent.width - parent.width - 2, (parent.wx - parent.posBaseX) * parent.scaleX)) })
                                        parent.y = Qt.binding(function() { return Math.max(18, Math.min(parent.parent.height - parent.height - 2, (parent.wy - parent.posBaseY) * parent.scaleY)) })
                                    }
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton) root.selectWindow(parent.address)
                                        else if (mouse.button === Qt.MiddleButton) Workspaces.closeWindow(parent.address)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.visibleSpecialWorkspaces.length > 0
            width: parent.width
            height: root.specialCellH
            radius: 10
            color: "#151515"
            border.width: 1
            border.color: "#2a2a2a"

            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                Repeater {
                    model: root.visibleSpecialWorkspaces
                    delegate: Rectangle {
                        required property string modelData
                        readonly property string name: modelData
                        width: root.specialCellW
                        height: root.specialCellH - 12
                        radius: 8
                        color: root.draggingTargetSpecialWorkspace === name ? "#20334e" : "#101010"
                        border.width: 1
                        border.color: root.draggingTargetSpecialWorkspace === name ? "#70a7ff" : "#2a2a2a"

                        Text {
                            anchors.centerIn: parent
                            text: name
                            color: "#dcdcdc"
                            elide: Text.ElideRight
                            width: parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                Workspaces.toggleSpecial(parent.name)
                                IslandState.send(IslandState.Event.Close)
                            }
                        }

                        DropArea {
                            anchors.fill: parent
                            onEntered: {
                                root.draggingTargetWorkspace = -1
                                root.draggingTargetSpecialWorkspace = parent.name
                            }
                            onExited: {
                                if (root.draggingTargetSpecialWorkspace === parent.name)
                                    root.draggingTargetSpecialWorkspace = ""
                            }
                        }
                    }
                }

                Rectangle {
                    width: 42
                    height: root.specialCellH - 12
                    radius: 8
                    color: root.draggingTargetSpecialWorkspace === root.createSpecialWorkspaceTarget ? "#28445f" : "#101010"
                    border.width: 1
                    border.color: root.draggingTargetSpecialWorkspace === root.createSpecialWorkspaceTarget ? "#70a7ff" : "#2a2a2a"

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: "#dcdcdc"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            const name = Workspaces.nextSpecialWorkspaceName(root.visibleSpecialWorkspaces)
                            Workspaces.toggleSpecial(name)
                            IslandState.send(IslandState.Event.Close)
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        onEntered: {
                            root.draggingTargetWorkspace = -1
                            root.draggingTargetSpecialWorkspace = root.createSpecialWorkspaceTarget
                        }
                        onExited: {
                            if (root.draggingTargetSpecialWorkspace === root.createSpecialWorkspaceTarget)
                                root.draggingTargetSpecialWorkspace = ""
                        }
                    }
                }
            }
        }
    }
}
