// Bar.qml

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

import qs.bar.buttons
import qs.services

Scope {
    id: root

    property real screenW: 0

    // -- timers: restart()/stop() only, never bound to "running" --
    Timer { id: peekTimer;    interval: 2000; repeat: false; onTriggered: BarState.transition("timerFired") }
    Timer { id: barViewTimer; interval: 3000; repeat: false; onTriggered: BarState.transition("barViewTimeout") }

    Connections {
        target: BarState
        function onTimerShouldRunChanged()       { BarState.timerShouldRun       ? peekTimer.restart()    : peekTimer.stop() }
        function onBarViewTimerShouldRunChanged() { BarState.barViewTimerShouldRun ? barViewTimer.restart() : barViewTimer.stop() }
    }

    // -- IPC --
    IpcHandler {
        target: "bar"

        function toggleHidden(): void   { BarState.toggleHidden() }
        function toggleAutohide(): void { BarState.toggleAutohide() }
        function collapse(): void       { BarState.collapse() }

        function setView(view: string): void {
            BarState.wake()
            BarState.currentView = view
            BarState.viewKind    = view === "tabs" ? "tabs" : "island"
        }

        function getMode(): string {
            switch (BarState.mode) {
                case BarState.normal:  return "normal"
                case BarState.peeking: return "peeking"
                case BarState.hidden:  return "hidden"
                default:               return "unknown"
            }
        }

        function getView(): string { return BarState.currentView }
    }

    // -- exclusion-zone spacer window --
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: BarState.autohide ? 0 : 64
            mask: Region {}
            color: "transparent"
        }
    }

    // -- actual bar window --
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: BarState.autohide ? WlrLayer.Overlay : WlrLayer.Top
            color: "transparent"

            Component.onCompleted: root.screenW = modelData.width

            mask: Region { item: BarState.catchOutsideClicks ? fullScreenMask : bar }
            Item { id: fullScreenMask; anchors.fill: parent }

            MouseArea {
                anchors.fill: parent
                enabled: BarState.catchOutsideClicks
                onClicked: BarState.transition("outsideClick")
            }

            Rectangle {
                id: bar

                readonly property int targetW: views.item ? views.item.targetWidth  : 1080
                readonly property int targetH: views.item ? views.item.targetHeight : 48

                width:          targetW
                implicitHeight: BarState.isHidden ? 1 : targetH

                x: {
                    var center = (root.screenW - targetW) / 2
                    return Math.max(8, Math.min(center + BarState.originX, root.screenW - targetW - 8))
                }

                anchors {
                    top: parent.top
                    topMargin: BarState.isHidden ? 0 : 8
                }

                color: "#c0141216"
                radius: 8
                clip: true

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: BarState.transition("surfaceClick")
                }

                HoverHandler {
                    onHoveredChanged: BarState.transition(hovered ? "hover" : "unhover")
                }

                // -- content lookup: one declared slot per id, no switch to grow --
                readonly property var contentMap: ({
                    tabs:       tabsComp,
                    clock:      clockComp,
                    launcher:   launcherComp,
                    workspaces: workspacesComp,
                    audio:      audioComp,
                    bluetooth:  bluetoothComp,
                    network:    networkComp,
                    power:      powerComp
                })

                Loader {
                    id: views
                    anchors.fill: parent
                    sourceComponent: bar.contentMap[BarState.currentView] ?? tabsComp
                }
            }
        }
    }

    Component {
        id: tabsComp
        Item {
            property int targetWidth:  1080
            property int targetHeight: 48

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8

                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Workspaces {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        screenW: root.screenW
                    }
                }

                Launcher {
                    Layout.alignment: Qt.AlignCenter
                    screenW: root.screenW
                }

                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    RowLayout {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Audio     { screenW: root.screenW }
                        Bluetooth { screenW: root.screenW }
                        Network   { screenW: root.screenW }
                        Power     { screenW: root.screenW }
                        Clock     { screenW: root.screenW }
                    }
                }
            }
        }
    }

    Component { id: clockComp;      Item { property int targetWidth: 420;  property int targetHeight: 220 } }
    Component { id: bluetoothComp;  Item { property int targetWidth: 420;  property int targetHeight: 220 } }
    
    Component {
        id: audioComp
        Item {
            readonly property bool isIsland: BarState.viewKind === "island"
            property int targetWidth:  isIsland ? 420 : 420
            property int targetHeight: isIsland ? 220 : 48

            Row {
                visible: !isIsland
                anchors.centerIn: parent
                spacing: 8
                Text { color: "white"; text: Volume.muted ? "Muted" : Volume.percent + "%" }
            }

            Column {
                visible: isIsland
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    font.pixelSize: 32
                    text: Volume.muted ? "Muted" : Volume.percent + "%"
                }

                Rectangle {
                    id: track
                    width: 280; height: 8; radius: 4
                    color: "#3a3540"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: track.width * Volume.volume
                        height: track.height
                        radius: 4
                        color: "#8a7fff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed:   (m) => Volume.setVolume(m.x / track.width)
                        onPositionChanged: (m) => { if (pressed) Volume.setVolume(m.x / track.width) }
                    }
                }
            }
        }
    }
    
    Component { id: powerComp;      Item { property int targetWidth: 420;  property int targetHeight: 220 } }
    Component { id: networkComp;    Item { property int targetWidth: 420;  property int targetHeight: 220 } }
    Component { id: launcherComp;   Item { property int targetWidth: 600;  property int targetHeight: 600 } }
    Component { id: workspacesComp; Item { property int targetWidth: 1080; property int targetHeight: 720 } }
}