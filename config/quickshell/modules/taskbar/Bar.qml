import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland


// Windows + raw input. Turns pointer/keyboard into events; knows nothing about views.
Scope {
    id: root

    Ipc {}
    Triggers {}
    // Debug{}

    // Reserves the exclusive zone for the collapsed handle. Never takes input.
    PanelWindow {
        anchors { top: true; left: true; right: true }
        implicitHeight: IslandState.space ? island.reservedH : 0
        mask: Region {}
        color: "transparent"
    }

    // The real window: covers the whole screen so it can catch outside clicks,
    // but the input mask keeps it click-through except where we need input.
    PanelWindow {
        id: win

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "quickshell:island"
        WlrLayershell.layer: WlrLayer.Top
        // OnDemand only hands over the keyboard after a click. Views that declare `keys: true`
        // in Registry get Exclusive so typing works the instant they open.
        WlrLayershell.keyboardFocus: IslandState.keyboard ? WlrKeyboardFocus.Exclusive
                                   : IslandState.pinned   ? WlrKeyboardFocus.OnDemand
                                                          : WlrKeyboardFocus.None

        // pinned: whole screen (catch outside clicks). otherwise: just the island.
        mask: Region { item: IslandState.pinned ? screenArea : hitArea }

        // Not used for keyboard views: Exclusive focus already owns the keyboard, and the
        // full-screen screenArea below still catches outside clicks. Leaving the grab on
        // made the focus change to Exclusive fire onCleared -> Outside -> instant close.
        HyprlandFocusGrab {
            windows: [win]
            active: IslandState.pinned && !IslandState.keyboard
            onCleared: IslandState.send(IslandState.Event.Outside)
        }

        Item {
            id: screenArea
            anchors.fill: parent
            // yields focus to the view when it wants the keyboard
            focus: IslandState.pinned && !IslandState.keyboard
            Keys.onEscapePressed: IslandState.send(IslandState.Event.Escape)

            MouseArea {
                anchors.fill: parent
                enabled: IslandState.pinned
                onClicked: IslandState.send(IslandState.Event.Outside)
            }
        }

        // Island's bounding box + padding container.
        // Anchored permanently to top: 0 so expanding downward never causes the hit area
        // to leave a pointer resting near the top screen edge.
        Item {
            id: hitArea

            readonly property int pad: 8

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 0  // Locked at 0 to maintain continuous mouse hit testing

            width: island.width + pad * 2
            // Height spans from the screen top through the gap offset down to the bottom padding
            height: (island.open ? island.topGap : 0) + island.height + pad

            // Escape from a focused view bubbles up to here (screenArea no longer holds focus then)
            Keys.onEscapePressed: IslandState.send(IslandState.Event.Escape)

            // z: -1 ensures controls and buttons inside views win click events.
            // Keyboard views aren't dismissed by a click on dead space; they use Escape/outside click.
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: IslandState.send(IslandState.Event.Click)
            }

            HoverHandler {
                onHoveredChanged: IslandState.send(hovered ? IslandState.Event.HoverIn
                                                           : IslandState.Event.HoverOut)
            }

            Island {
                id: island
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                // Apply vertical gap offset inside hitArea so visual morphing remains bounded
                anchors.topMargin: island.open ? island.topGap : 0

                // Smoothly animate the top margin transition in sync with body width/height morphing
                Behavior on anchors.topMargin {
                    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}