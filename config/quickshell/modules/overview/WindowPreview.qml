import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.modules.services

Item {
    id: root

    property var toplevel: null
    readonly property string address: Toplevels.addressOf(toplevel)
    readonly property var windowData: Desktops.windowByAddress[address] ?? null
    readonly property var monitorData: Desktops.monitorById(windowData?.monitor)
    readonly property int workspaceId: Number(windowData?.workspace?.id ?? -1)

    property var widgetMonitorData: null
    property int widgetMonitorId: 0
    property real previewScale: 0.16
    property real availableWorkspaceWidth: 0
    property real availableWorkspaceHeight: 0
    property real positionBaseX: (monitorData?.x ?? 0) + (monitorData?.reserved?.[0] ?? 0)
    property real positionBaseY: (monitorData?.y ?? 0) + (monitorData?.reserved?.[1] ?? 0)
    property real xOffset: 0
    property real yOffset: 0
    property real geometryScaleX: widthRatio
    property real geometryScaleY: heightRatio
    property bool animateSize: true
    property int baseZ: OverviewConfig.windowZ
    property int recaptureToken: 0

    property QtObject dnd: null
    property Item tip: null
    property Item homeParent: null            // set together with dragLayer: re-parent while dragging, so a
    property Item dragLayer: null             // clipped container (special tile) cannot cut the thumbnail off

    signal activated(string address)

    // A window on another monitor is drawn relative to *this* monitor's tile.
    readonly property real widthRatio: {
        if (!widgetMonitorData || !monitorData) return 1
        const widgetW = (widgetMonitorData.transform % 2 === 1) ? widgetMonitorData.height : widgetMonitorData.width
        const sourceW = (monitorData.transform % 2 === 1) ? monitorData.height : monitorData.width
        return (widgetW * (monitorData.scale ?? 1)) / (sourceW * (widgetMonitorData.scale ?? 1))
    }
    readonly property real heightRatio: {
        if (!widgetMonitorData || !monitorData) return 1
        const widgetH = (widgetMonitorData.transform % 2 === 1) ? widgetMonitorData.width : widgetMonitorData.height
        const sourceH = (monitorData.transform % 2 === 1) ? monitorData.width : monitorData.height
        return (widgetH * (monitorData.scale ?? 1)) / (sourceH * (widgetMonitorData.scale ?? 1))
    }

    readonly property real initX: Math.max(((windowData?.at?.[0] ?? 0) - positionBaseX) * previewScale * geometryScaleX, 0) + xOffset
    readonly property real initY: Math.max(((windowData?.at?.[1] ?? 0) - positionBaseY) * previewScale * geometryScaleY, 0) + yOffset
    readonly property real targetWindowWidth: (windowData?.size?.[0] ?? 100) * previewScale * geometryScaleX
    readonly property real targetWindowHeight: (windowData?.size?.[1] ?? 100) * previewScale * geometryScaleY
    readonly property bool atInitPosition: x === initX && y === initY

    property bool hovered: false
    property bool pressed: false
    property bool dragInProgress: false
    property bool suspendPositionAnimation: false
    property bool initialized: false
    property bool previewCaptureEnabled: true

    readonly property bool onWidgetMonitor: (windowData?.monitor ?? -1) === widgetMonitorId
    readonly property bool compactMode: targetWindowHeight < OverviewConfig.compactThreshold
                                        || targetWindowWidth < OverviewConfig.compactThreshold
    readonly property bool shouldCapture: OverviewConfig.previewsEnabled && previewCaptureEnabled
                                          && (OverviewConfig.includeInactiveMonitorPreviews || onWidgetMonitor)
    readonly property real cornerRadius: OverviewConfig.windowRounding * previewScale

    readonly property string tooltipText: windowData
        ? `${windowData.title ?? "Unknown"}\n[${windowData.class ?? "unknown"}] ${windowData.xwayland ? "[XWayland] " : ""}`
        : ""

    readonly property var desktopEntry: {
        DesktopEntries.applications.values          // re-run when the entry index updates
        return DesktopEntries.heuristicLookup(windowData?.class)
    }
    readonly property string iconName: {
        const raw = String(desktopEntry?.icon ?? "").trim()
        const bare = raw.replace(/^image:\/\/icon\//, "").split("?")[0].trim()
        return bare.length > 0 ? bare : "application-x-executable"
    }

    x: initX
    y: initY
    z: (dragInProgress || !atInitPosition) ? OverviewConfig.dragZ : baseZ
    width: Math.min(targetWindowWidth, availableWorkspaceWidth)
    height: Math.min(targetWindowHeight, availableWorkspaceHeight)
    opacity: onWidgetMonitor ? 1 : OverviewConfig.inactiveMonitorOpacity
    clip: true

    // Hide windows covered by a fullscreen window on their workspace (unless it is the fullscreen one).
    visible: {
        const ws = windowData?.workspace?.id
        if ((windowData?.fullscreen ?? 0) > 0 || ws === undefined) return true
        return !Desktops.windowList.some(w => w.workspace?.id === ws && (w.fullscreen ?? 0) > 0)
    }

    Component.onCompleted: Qt.callLater(() => root.initialized = true)

    Behavior on x {
        enabled: root.initialized && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation { duration: OverviewConfig.moveEnterMs; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        enabled: root.initialized && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation { duration: OverviewConfig.moveEnterMs; easing.type: Easing.OutCubic }
    }
    Behavior on width {
        enabled: root.initialized && root.animateSize && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation { duration: OverviewConfig.moveEnterMs; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        enabled: root.initialized && root.animateSize && !root.dragInProgress && !root.suspendPositionAnimation
        NumberAnimation { duration: OverviewConfig.moveEnterMs; easing.type: Easing.OutCubic }
    }

    // Opaque backing for windows on this monitor, so nothing behind the island shows through the preview.
    Rectangle {
        visible: root.onWidgetMonitor
        anchors.fill: parent
        radius: root.cornerRadius
        color: OverviewConfig.colors.window
    }

    ScreencopyView {
        id: capture

        readonly property real srcAspect: {
            const w = root.windowData?.size?.[0] ?? 0
            const h = root.windowData?.size?.[1] ?? 0
            return (w > 0 && h > 0) ? (w / h) : 1
        }

        anchors.centerIn: parent
        width: OverviewConfig.cropToFill ? Math.max(parent.width, parent.height * srcAspect)
                                         : Math.min(parent.width, parent.height * srcAspect)
        height: OverviewConfig.cropToFill ? Math.max(parent.height, parent.width / srcAspect)
                                          : Math.min(parent.height, parent.width / srcAspect)
        captureSource: root.shouldCapture ? root.toplevel : null
        live: OverviewConfig.livePreviews

        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: previewMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    // the app icon: all a thumbnail shows until the first frame arrives
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.pressed
               ? Qt.alpha(OverviewConfig.colors.windowActive, Math.min(1, OverviewConfig.windowOverlayOpacity + 0.30))
               : root.hovered
                 ? Qt.alpha(OverviewConfig.colors.windowHover, Math.min(1, OverviewConfig.windowOverlayOpacity + 0.20))
                 : Qt.alpha(OverviewConfig.colors.window, OverviewConfig.windowOverlayOpacity)
        border.width: 1
        border.color: Qt.alpha(OverviewConfig.colors.windowOutline, 0.3)

        Image {
            readonly property real iconSize: Math.min(root.width, root.height)
                * (root.compactMode ? OverviewConfig.iconToWindowRatioCompact : OverviewConfig.iconToWindowRatio)
                / (root.monitorData?.scale ?? 1)

            visible: OverviewConfig.showIcons
            anchors.centerIn: parent
            width: iconSize
            height: iconSize
            source: Quickshell.iconPath(root.iconName, "image-missing")
            sourceSize: Qt.size(Math.max(1, Math.round(iconSize)), Math.max(1, Math.round(iconSize)))
        }
    }

    Item {
        id: previewMask
        anchors.centerIn: parent
        width: capture.width
        height: capture.height
        visible: false
        layer.enabled: true
        layer.smooth: true

        Rectangle {
            anchors.centerIn: parent
            width: root.width
            height: root.height
            radius: root.cornerRadius
        }
    }

    function drop() {
        if (!dnd || !address) return false
        const targetWorkspace = dnd.targetWorkspace
        const targetSpecial = dnd.targetSpecial
        const ownSpecial = Desktops.specialWorkspaceName(windowData)

        if (targetSpecial === dnd.createTarget) {
            Desktops.moveWindowToSpecial(address, Desktops.nextSpecialWorkspaceName(dnd.specialNames))
            return true
        }
        if (targetSpecial.length > 0 && targetSpecial !== ownSpecial) {
            Desktops.moveWindowToSpecial(address, targetSpecial)
            return true
        }
        if (targetWorkspace > 0 && targetWorkspace !== workspaceId) {
            Desktops.moveWindowToWorkspace(address, targetWorkspace)
            return true
        }
        return false
    }

    function moveToDragLayer() {
        const p = root.mapToItem(dragLayer, 0, 0)
        suspendPositionAnimation = true
        parent = dragLayer
        x = p.x
        y = p.y
        Qt.callLater(() => root.suspendPositionAnimation = false)
    }

    // Put the thumbnail back where the window data says it is. x/y are re-bound (not assigned), so later
    // geometry updates keep moving it: dragging overwrote the original bindings.
    function returnHome() {
        const reparent = homeParent !== null && parent !== homeParent
        if (reparent) {
            suspendPositionAnimation = true
            parent = homeParent
        }
        x = Qt.binding(() => root.initX)
        y = Qt.binding(() => root.initY)
        if (reparent) Qt.callLater(() => root.suspendPositionAnimation = false)
    }

    function beginDrag(mouse) {
        pressed = true
        dragInProgress = true
        tip?.hide(root)
        if (dnd) {
            dnd.fromWorkspace = workspaceId
            dnd.targetWorkspace = -1
            dnd.targetSpecial = ""
        }
        Drag.source = root
        Drag.hotSpot.x = mouse.x
        Drag.hotSpot.y = mouse.y
        if (dragLayer) moveToDragLayer()
        Drag.active = true
    }

    function endDrag() {
        const moved = drop()
        pressed = false
        Drag.active = false
        dragInProgress = false
        dnd?.reset()
        // After a move, wait for hyprctl to report the new workspace so the thumbnail glides there
        // instead of flashing back to its old spot first.
        if (moved) settle.restart()
        else returnHome()
    }

    Timer {
        id: settle
        interval: OverviewConfig.raceDelayMs
        onTriggered: root.returnHome()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: root

        onEntered: {
            root.hovered = true
            if (!root.dragInProgress && root.tooltipText.length > 0) root.tip?.show(root, root.tooltipText)
        }
        onExited: {
            root.hovered = false
            root.tip?.hide(root)
        }
        onPressed: mouse => root.beginDrag(mouse)
        onReleased: root.endDrag()
        onCanceled: if (root.dragInProgress) root.endDrag()
        onClicked: mouse => {
            if (!root.address) return
            if (mouse.button === Qt.LeftButton) root.activated(root.address)
            else if (mouse.button === Qt.MiddleButton) Desktops.closeWindow(root.address)
            mouse.accepted = true
        }
    }

    function refreshCapture() {
        if (OverviewConfig.livePreviews || !OverviewConfig.previewsEnabled) return
        previewCaptureEnabled = false
        recapture.restart()
    }

    Timer {
        id: recapture
        interval: Math.max(1, OverviewConfig.previewRecaptureDelayMs)
        onTriggered: root.previewCaptureEnabled = true
    }

    onRecaptureTokenChanged: if (recaptureToken > 0) refreshCapture()
}