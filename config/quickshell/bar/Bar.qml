// Bar.qml

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

import qs.bar.buttons
import qs.bar.views
import qs.bar.islands
import qs.services

Scope {
    id: root

    property real screenW: 0

    function resolveComp(view, kind) {
        switch (view + "|" + kind) {
            case "audio|bar":         return audioBarComp
            case "audio|island":      return audioIslandComp
            case "clock|island":      return clockComp
            case "bluetooth|island":  return bluetoothComp
            case "network|island":    return networkComp
            case "power|island":      return powerComp
            case "launcher|island":   return launcherComp
            case "workspaces|island": return workspacesComp
            case "brightness|bar":    return brightnessBarComp
            default:                  return tabsComp
        }
    }


    Timer {
        id: hideTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (BarState.viewKind === "bar") BarState.collapse()
            if (BarState.shouldHide) BarState.mode = BarState.hidden
        }
    }

    Connections {
        target: BarState
        function onShouldHideChanged()      { BarState.shouldHide ? hideTimer.restart() : hideTimer.stop() }
        function onShowBarViewTickChanged() { hideTimer.restart() }
    }

    IpcHandler {
        target: "bar"

        function toggleHidden(): void   { BarState.toggleHidden() }
        function toggleAutohide(): void { BarState.toggleAutohide() }
        function collapse(): void       { BarState.collapse() }

        function setView(view: string): void {
            if (view === "tabs") {
                BarState.collapse()
                return
            }

            // Pressing the bind for the island that's already open closes it
            if (BarState.viewKind === "island" && BarState.currentView === view) {
                BarState.collapse()
                return
            }

            BarState.wake()
            BarState.currentView = view
            BarState.viewKind    = "island"
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
            id: panelWin
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: BarState.autohide ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.keyboardFocus: BarState.isExpanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            Component.onCompleted: root.screenW = modelData.width

            mask: Region { item: BarState.catchOutsideClicks ? fullScreenMask : bar }

            HyprlandFocusGrab {
                id: focusGrab
                windows: [ panelWin ]
                active: BarState.isExpanded
                onCleared: BarState.transition("outsideClick")
            }

            Item {
                id: fullScreenMask
                anchors.fill: parent
                focus: BarState.isExpanded
                Keys.onEscapePressed: BarState.transition("escape")

                MouseArea {
                    anchors.fill: parent
                    enabled: BarState.catchOutsideClicks
                    onClicked: BarState.transition("outsideClick")
                }
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

                Loader {
                    id: views
                    anchors.fill: parent
                    sourceComponent: root.resolveComp(BarState.currentView, BarState.viewKind)
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

    Component { id: clockComp;       Item { property int targetWidth: 420;  property int targetHeight: 220 } }
    Component { id: bluetoothComp;   Item { property int targetWidth: 420;  property int targetHeight: 220 } }
    Component { id: audioIslandComp; AudioIsland {} }
    Component { id: audioBarComp;    AudioBar    {} }
    Component { id: powerComp;       PowerIsland {} }
    Component { id: brightnessBarComp; BrightnessBar {} }
    Component { id: networkComp;     Item { property int targetWidth: 420;  property int targetHeight: 220 } }
    Component { id: launcherComp;    Item { property int targetWidth: 600;  property int targetHeight: 600 } }
    Component { id: workspacesComp;  Item { property int targetWidth: 1080; property int targetHeight: 720 } }
}