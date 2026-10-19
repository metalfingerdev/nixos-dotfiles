import QtQuick
import Quickshell
import qs.modules.services

// One special workspace ("scratchpad"). The tile is sized to the bounding box of the windows inside it,
// so a floating terminal looks like a floating terminal instead of being stretched to the monitor's aspect.
Rectangle {
    id: root

    property string specialName: ""
    property var monitorData: null            // monitor the island is on
    property int monitorId: 0
    property real previewScale: 0.16
    property real fallbackWidth: 0            // empty special workspace: pretend it is a full monitor (px at previewScale)
    property real fallbackHeight: 0
    property QtObject dnd: null
    property Item tip: null
    property Item dragLayer: null
    property int recaptureToken: 0

    signal toggleRequested(string name)
    signal windowActivated(string address)

    readonly property var geometry: Workspaces.specialGeometry(specialName, monitorId)
    readonly property bool hasGeometry: Number.isFinite(geometry?.width) && Number.isFinite(geometry?.height)
                                        && geometry.width > 0 && geometry.height > 0
    readonly property real geometryWidth: hasGeometry ? geometry.width : Math.max(1, fallbackWidth / previewScale)
    readonly property real geometryHeight: hasGeometry ? geometry.height : Math.max(1, fallbackHeight / previewScale)
    readonly property real fitScale: hasGeometry ? Math.min(width / geometryWidth, height / geometryHeight) : previewScale
    readonly property real contentWidth: hasGeometry ? geometryWidth * fitScale : width
    readonly property real contentHeight: hasGeometry ? geometryHeight * fitScale : height

    readonly property bool dropHover: dnd !== null && dnd.targetSpecial === specialName
    readonly property bool hasWallpaper: OverviewConfig.specialEmptyWorkspaceWallpaper.trim().length > 0

    radius: Math.max(4, OverviewConfig.screenRounding * previewScale)
    clip: true
    color: hasWallpaper ? "transparent" : Qt.alpha(dropHover ? OverviewConfig.colors.tileHover : OverviewConfig.colors.stripTile,
                                                    OverviewConfig.workspaceOpacity)
    border.width: 1
    border.color: dropHover ? OverviewConfig.colors.accent : Qt.alpha(OverviewConfig.colors.stripBorder, 0.75)

    RoundedImage {
        anchors.fill: parent
        radius: root.radius
        source: OverviewConfig.wallpaperUrl(OverviewConfig.specialEmptyWorkspaceWallpaper)
    }

    Text {
        anchors.centerIn: parent
        visible: !root.hasGeometry
        width: parent.width - 8
        text: root.specialName.replace(/[-_]+/g, " ")
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Math.round(Math.max(9, Math.min(14, root.height * 0.18)))
        color: Qt.alpha(OverviewConfig.colors.textDim, 0.55)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: if (!root.dnd || root.dnd.idle) root.toggleRequested(root.specialName)
    }

    DropArea {
        anchors.fill: parent
        onEntered: {
            if (!root.dnd) return
            root.dnd.targetWorkspace = -1
            root.dnd.targetSpecial = root.specialName
        }
        onExited: {
            if (root.dnd && root.dnd.targetSpecial === root.specialName)
                root.dnd.targetSpecial = ""
        }
    }

    Item {
        id: content
        x: Math.max(0, (root.width - width) / 2)
        y: Math.max(0, (root.height - height) / 2)
        width: root.contentWidth
        height: root.contentHeight
        clip: true

        Repeater {
            model: ScriptModel {
                values: root.hasGeometry ? Toplevels.onSpecial(root.specialName, root.monitorId) : []
            }

            delegate: WindowPreview {
                id: win
                required property var modelData

                toplevel: modelData
                dnd: root.dnd
                tip: root.tip
                homeParent: content
                dragLayer: root.dragLayer
                widgetMonitorData: root.monitorData
                widgetMonitorId: root.monitorId
                previewScale: root.previewScale
                availableWorkspaceWidth: content.width
                availableWorkspaceHeight: content.height
                positionBaseX: root.geometry?.x ?? 0
                positionBaseY: root.geometry?.y ?? 0
                geometryScaleX: root.fitScale / root.previewScale
                geometryScaleY: root.fitScale / root.previewScale
                animateSize: false
                baseZ: Workspaces.specialStackZ(windowData)
                recaptureToken: root.recaptureToken

                onActivated: address => root.windowActivated(address)
            }
        }
    }
}