import QtQuick
import qs.modules.services

// The "Special Workspaces" band under the grid: one tile per special workspace plus a "+" tile
// (click: open a new one, drop a window on it: move the window into a fresh one).
Item {
    id: root

    property var names: []
    property real sectionWidth: 0             // = width of the workspace grid above
    property real tileHeight: 0               // same height as a normal workspace tile
    property real fallbackTileWidth: 0
    property real previewScale: 0.16
    property real spacing: 5
    property var monitorData: null
    property int monitorId: 0
    property QtObject dnd: null
    property Item tip: null
    property Item dragLayer: null
    property int recaptureToken: 0

    signal toggleRequested(string name)
    signal createRequested()
    signal windowActivated(string address)

    readonly property real padding: Math.max(8, 12 * previewScale)
    readonly property real titleHeight: Math.max(14, OverviewConfig.fontSmall * previewScale)
    readonly property real titleGap: Math.max(6, 8 * previewScale)

    readonly property int totalTiles: names.length + 1
    readonly property int columns: Math.max(1, Math.min(Math.max(1, OverviewConfig.specialWorkspaceColumns), totalTiles))
    readonly property int tileRows: Math.ceil(totalTiles / columns)
    readonly property real innerWidth: Math.max(0, sectionWidth - padding * 2)

    // Wide special workspaces (e.g. a floating browser) may be wider than a normal tile, but never wider than the cap.
    readonly property real aspectCap: {
        let widest = Math.max(1, fallbackTileWidth / Math.max(1, tileHeight))
        for (const name of names) {
            const g = Workspaces.specialGeometry(name, monitorId)
            if (!Number.isFinite(g?.width) || !Number.isFinite(g?.height) || g.height <= 0) continue
            widest = Math.max(widest, g.width / g.height)
        }
        return widest
    }
    readonly property real tileWidth: {
        const raw = (innerWidth - (columns - 1) * spacing) / columns
        return Math.max(80 * previewScale, Math.min(raw, tileHeight * aspectCap))
    }
    readonly property real gridWidth: columns * tileWidth + (columns - 1) * spacing
    readonly property real gridHeight: tileRows * tileHeight + (tileRows - 1) * spacing

    readonly property bool createHover: dnd !== null && dnd.targetSpecial === dnd.createTarget

    width: sectionWidth
    height: padding * 2 + titleHeight + titleGap + gridHeight

    Rectangle {
        anchors.fill: parent
        radius: OverviewConfig.normalRounding * root.previewScale
        color: Qt.alpha(OverviewConfig.colors.strip, OverviewConfig.workspaceOpacity)
        border.width: 1
        border.color: Qt.alpha(OverviewConfig.colors.stripBorder, 0.65)

        // header band
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Math.max(18 * root.previewScale, root.padding + root.titleHeight * 0.8)
            radius: parent.radius
            color: Qt.alpha(OverviewConfig.colors.accent, 0.08)
        }

        Text {
            x: root.padding
            y: root.padding
            text: "Special Workspaces"
            font.pixelSize: Math.round(root.titleHeight)
            font.weight: Font.DemiBold
            color: Qt.alpha(OverviewConfig.colors.text, 0.84)
        }
    }

    Grid {
        x: root.padding + Math.max(0, (root.innerWidth - root.gridWidth) / 2)
        y: root.padding + root.titleHeight + root.titleGap
        width: root.gridWidth
        columns: root.columns
        rowSpacing: root.spacing
        columnSpacing: root.spacing

        Repeater {
            model: root.names

            delegate: SpecialTile {
                required property string modelData

                width: root.tileWidth
                height: root.tileHeight
                specialName: modelData
                monitorData: root.monitorData
                monitorId: root.monitorId
                previewScale: root.previewScale
                fallbackWidth: root.fallbackTileWidth
                fallbackHeight: root.tileHeight
                dnd: root.dnd
                tip: root.tip
                dragLayer: root.dragLayer
                recaptureToken: root.recaptureToken

                onToggleRequested: name => root.toggleRequested(name)
                onWindowActivated: address => root.windowActivated(address)
            }
        }

        // "+" tile
        Rectangle {
            id: createTile

            readonly property bool hasWallpaper: OverviewConfig.specialEmptyWorkspaceWallpaper.trim().length > 0

            width: root.tileWidth
            height: root.tileHeight
            radius: Math.max(4, OverviewConfig.screenRounding * root.previewScale)
            color: hasWallpaper ? "transparent"
                                : Qt.alpha(OverviewConfig.colors.createTile, root.createHover ? 0.9 : OverviewConfig.workspaceOpacity)
            border.width: 1
            border.color: root.createHover ? OverviewConfig.colors.accent : Qt.alpha(OverviewConfig.colors.accent, 0.46)

            RoundedImage {
                anchors.fill: parent
                radius: createTile.radius
                source: OverviewConfig.wallpaperUrl(OverviewConfig.specialEmptyWorkspaceWallpaper)
            }

            Text {
                anchors.centerIn: parent
                text: root.createHover ? "Release" : "+"
                font.pixelSize: Math.round(root.createHover ? Math.max(11, createTile.height * 0.22)
                                                 : Math.max(14, createTile.height * 0.40))
                font.weight: Font.DemiBold
                color: Qt.alpha(OverviewConfig.colors.text, 0.92)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: if (!root.dnd || root.dnd.idle) root.createRequested()
            }

            DropArea {
                anchors.fill: parent
                onEntered: {
                    if (!root.dnd) return
                    root.dnd.targetWorkspace = -1
                    root.dnd.targetSpecial = root.dnd.createTarget
                }
                onExited: {
                    if (root.dnd && root.dnd.targetSpecial === root.dnd.createTarget)
                        root.dnd.targetSpecial = ""
                }
            }
        }
    }
}