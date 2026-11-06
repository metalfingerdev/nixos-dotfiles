import QtQuick
import Quickshell
import qs.modules.services
import qs.modules.components
import qs.modules.island
import qs.modules.parts

// One view, two faces, picked by the phase: the popups as a toast (Triggers closes it when the last
// one goes), the center when pinned.
Item {
    id: root

    readonly property bool center: Engine.pinned
    readonly property var popups: Notifier.popups.slice(0, Notifier.maxPopups)
    readonly property int more: Notifier.popups.length - popups.length

    implicitWidth: center ? 720 : 480
    implicitHeight: (center ? centerColumn.implicitHeight : popupColumn.implicitHeight) + (center ? 48 : 16)

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

        Label {
            visible: root.more > 0
            leftPadding: 12
            text: "+" + root.more + " more"
            color: Config.dim
            font.pixelSize: Config.small + 1
        }
    }

    Column {
        id: centerColumn
        visible: root.center
        x: 24; y: 24
        width: parent.width - 48
        spacing: 14

        Header {
            width: parent.width
            title: "Notifications"
            subtitle: Notifier.count === 0 ? "" : Notifier.count === 1 ? "1 notification" : Notifier.count + " notifications"
            onBack: Engine.back()

            Pill {
                icon: Notifier.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                text: "Do not disturb"
                implicitHeight: 48
                active: Notifier.dnd
                shortcut: "d"
                onClicked: Notifier.dnd = !Notifier.dnd
            }
            Pill {
                visible: Notifier.count > 0
                implicitHeight: 48
                kind: "text"
                text: "Clear all"
                shortcut: "c"
                onClicked: Notifier.dismissAll()
            }
        }

        ScrollList {
            id: notes
            visible: Notifier.count > 0
            width: parent.width
            maxHeight: 600
            spacing: 10

            Repeater {
                model: ScriptModel { values: root.center ? Notifier.items : []; objectProp: "id" }
                delegate: NotificationCard {
                    width: notes.innerWidth
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
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifier.dnd ? "Do not disturb is on" : "No notifications"
                color: Config.dim
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Enter", "open"], ["Del", "dismiss"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
