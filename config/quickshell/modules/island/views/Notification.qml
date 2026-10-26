import QtQuick
import Quickshell
import qs.modules.services
import qs.modules.components
import qs.modules.island
import qs.modules.island.parts

// The Notifications view. One view, two faces, picked by the phase:
//   popup  (Toast): dunst-style ephemeral cards. Lives as long as Notifier.popups is non-empty
//          (Triggers closes it when the last one goes).
//            left click: close it (it stays in the center)  middle: default action  right: close all
//   center (Pinned, e.g. `qs ipc call island open notifications`): everything not dismissed,
//          newest first, scrollable, with Do not disturb and Clear all.
//            click: default action   x: dismiss
Item {
    id: root

    readonly property bool center: Engine.pinned
    readonly property var popups: Notifier.popups.slice(0, Notifier.maxPopups)
    readonly property int more: Notifier.popups.length - popups.length

    implicitWidth: 420
    implicitHeight: (center ? centerColumn.implicitHeight : popupColumn.implicitHeight) + (center ? 32 : 16)

    // ---- popups: the first few, critical first; the rest wait ----
    Column {
        id: popupColumn
        visible: !root.center
        x: 8; y: 8
        width: parent.width - 16
        spacing: 6

        Repeater {
            model: root.center ? [] : root.popups
            delegate: NotificationCard {
                width: popupColumn.width
                center: false
            }
        }

        Text {
            visible: root.more > 0
            leftPadding: 12
            text: "+" + root.more + " more"
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.small + 1
        }
    }

    // ---- center: everything ----
    Column {
        id: centerColumn
        visible: root.center
        x: 16; y: 16
        width: parent.width - 32
        spacing: 10

        Header {
            width: parent.width
            title: "Notifications"
            subtitle: Notifier.count === 0 ? "" : Notifier.count === 1 ? "1 notification" : Notifier.count + " notifications"
            onBack: Engine.back()

            Pill {
                icon: Notifier.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                active: Notifier.dnd
                onClicked: Notifier.dnd = !Notifier.dnd
            }
            Pill {
                visible: Notifier.count > 0
                kind: "text"
                text: "Clear all"
                onClicked: Notifier.dismissAll()
            }
        }

        ScrollList {
            id: notes
            visible: Notifier.count > 0
            width: parent.width
            maxHeight: 520
            spacing: 8

            Repeater {
                model: ScriptModel { values: root.center ? Notifier.items : []; objectProp: "id" }
                delegate: NotificationCard {
                    width: notes.width
                    center: true
                }
            }
        }

        Column {
            visible: Notifier.count === 0
            width: parent.width
            topPadding: 12
            bottomPadding: 12
            spacing: 8

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: Notifier.dnd ? "notifications_off" : "notifications_none"
                size: 36
                color: Config.outline
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifier.dnd ? "Do not disturb is on" : "No notifications"
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.body
            }
        }
    }
}
