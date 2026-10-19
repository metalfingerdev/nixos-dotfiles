import QtQuick
import qs.modules.services

// One cell of the workspace grid: the big faded number, an optional wallpaper, and a drop target.
// Window previews are NOT children: they live in a layer above the whole grid so they can be dragged across tiles.
Rectangle {
    id: root

    property int workspaceId: 1
    property real previewScale: 0.16
    property real numberSize: 40
    property QtObject dnd: null

    signal activated(int workspaceId)

    readonly property bool dropHover: dnd !== null
                                      && dnd.targetWorkspace === workspaceId
                                      && dnd.fromWorkspace !== workspaceId
    readonly property bool hasWallpaper: OverviewConfig.emptyWorkspaceWallpaper.trim().length > 0
    readonly property color base: dropHover ? OverviewConfig.colors.tileHover : OverviewConfig.colors.tile

    radius: Math.max(4, OverviewConfig.screenRounding * previewScale)
    color: hasWallpaper ? "transparent" : Qt.alpha(base, OverviewConfig.workspaceOpacity)
    border.width: 2
    border.color: dropHover ? OverviewConfig.colors.tileHoverBorder : "transparent"

    RoundedImage {
        anchors.fill: parent
        radius: root.radius
        source: OverviewConfig.wallpaperUrl(OverviewConfig.emptyWorkspaceWallpaper)
    }

    // tint over the wallpaper so numbers/previews stay readable
    Rectangle {
        visible: root.hasWallpaper
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(root.base, root.dropHover
                                   ? Math.min(0.28, OverviewConfig.emptyWallpaperOverlayOpacity + 0.08)
                                   : OverviewConfig.emptyWallpaperOverlayOpacity)
    }

    Text {
        anchors.centerIn: parent
        visible: !root.hasWallpaper
        text: root.workspaceId
        font.pixelSize: Math.round(root.numberSize)
        font.weight: Font.DemiBold
        color: Qt.alpha(OverviewConfig.colors.number, 0.2)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: if (!root.dnd || root.dnd.idle) root.activated(root.workspaceId)
    }

    DropArea {
        anchors.fill: parent
        onEntered: {
            if (!root.dnd) return
            root.dnd.targetSpecial = ""
            root.dnd.targetWorkspace = root.workspaceId
        }
        onExited: {
            if (root.dnd && root.dnd.targetWorkspace === root.workspaceId)
                root.dnd.targetWorkspace = -1
        }
    }
}