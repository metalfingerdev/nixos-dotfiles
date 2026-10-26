import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.services
import qs.modules.components
import qs.modules.island

// The Notifications view. One view, two faces, picked by the phase:
//   popup  (Toast): dunst-style ephemeral toasts. Lives as long as Notifier.popups is non-empty
//          (Triggers closes it when the last one goes).
//            left click: close it (it stays in the center)  middle: default action  right: close all
//   center (Pinned, e.g. `qs ipc call island open notifications`): everything not dismissed,
//          newest first, scrollable.
//            click: default action   x: dismiss   clear: dismiss all
Item {
    id: root

    readonly property bool center: Engine.pinned

    readonly property var list: center ? Notifier.items : Notifier.popups
    readonly property int limit: center ? 6 : Notifier.maxPopups
    readonly property int rows: Math.min(list.length, limit)
    readonly property int more: center ? 0 : list.length - rows

    readonly property int rowH: 56
    readonly property int headerH: center ? 40 : 0
    readonly property int emptyH: center && list.length === 0 ? 40 : 0
    readonly property int moreH: more > 0 ? 22 : 0

    implicitWidth: 400
    implicitHeight: headerH + rows * rowH + emptyH + moreH + 8      // the island morphs to this

    function iconFor(name) {
        if (!name) return ""
        if (name.startsWith("/")) return "file://" + name
        if (name.includes("://")) return name
        return Quickshell.iconPath(name, true)
    }

    function popupClick(id, button) {
        if (button === Qt.MiddleButton)     Notifier.invoke(id, "default")
        else if (button === Qt.RightButton) Notifier.closeAll()
        else                                Notifier.close(id)
    }

    component Entry: Item {
        id: entry
        required property var modelData
        readonly property var n: modelData.ref

        width: root.width
        height: root.rowH

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: mouse => root.center ? Notifier.invoke(entry.modelData.id, "default")
                                            : root.popupClick(entry.modelData.id, mouse.button)
        }

        // urgency accent, like dunst's critical frame colour
        Rectangle {
            visible: entry.modelData.critical
            x: 6; width: 3; height: parent.height - 18; radius: 1.5
            anchors.verticalCenter: parent.verticalCenter
            color: Config.bad
        }

        Item {
            id: icon
            x: 16; width: 32; height: 32
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: picture
                anchors.fill: parent
                source: entry.n?.image ?? ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: source != ""
            }
            IconImage {
                anchors.fill: parent
                source: root.iconFor(entry.n?.appIcon ?? "")
                visible: !picture.visible && source != ""
            }
        }

        Column {
            anchors { left: icon.right; leftMargin: 12; right: side.left; rightMargin: 8
                      verticalCenter: parent.verticalCenter }
            spacing: 1

            Text {
                width: parent.width
                text: (entry.n?.appName || "notification")
                    + (root.center ? "  ·  " + Qt.formatTime(new Date(entry.modelData.time), "hh:mm") : "")
                elide: Text.ElideRight
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.small
            }
            Text {
                width: parent.width
                text: (entry.n?.summary ?? "") + (entry.modelData.count > 1 ? "  (" + entry.modelData.count + ")" : "")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: entry.modelData.critical ? Config.bad : Config.text
                font.family: Config.font
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: entry.n?.body ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Config.dim
                font.family: Config.font
                font.pixelSize: 12
            }
        }

        // center only: up to two named actions, and dismiss
        Row {
            id: side
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width: root.center ? implicitWidth : 0
            visible: root.center
            spacing: 6

            Repeater {
                model: root.center
                    ? Array.from(entry.n?.actions ?? []).filter(a => a.identifier !== "default").slice(0, 2)
                    : []
                delegate: Pill {
                    required property var modelData
                    text: modelData.text
                    onClicked: Notifier.invoke(entry.modelData.id, modelData.identifier)
                }
            }
            Pill { text: "x"; onClicked: Notifier.dismiss(entry.modelData.id) }
        }
    }

    // ---- center header ----
    Item {
        visible: root.center
        width: root.width
        height: root.headerH

        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: Notifier.count === 1 ? "1 notification" : Notifier.count + " notifications"
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.body
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Pill { text: "clear"; onClicked: Notifier.dismissAll() }
            Pill { text: "back";  onClicked: Engine.back() }
        }
    }

    // ---- center: scrollable, everything ----
    ListView {
        visible: root.center
        y: root.headerH
        width: root.width
        height: root.rows * root.rowH
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.center ? root.list : []
        delegate: Entry {}
    }

    // ---- popups: the first few, critical first; the rest wait ----
    Column {
        visible: !root.center
        width: root.width

        Repeater {
            model: root.center ? [] : root.list.slice(0, root.limit)
            delegate: Entry {}
        }
    }

    Text {
        visible: root.emptyH > 0
        x: 16; y: root.headerH + 10
        text: "No notifications"
        color: Config.dim
        font.family: Config.font
        font.pixelSize: Config.body
    }

    Text {
        visible: root.moreH > 0
        x: 16; y: root.rows * root.rowH + 2
        text: "+" + root.more + " more"
        color: Config.dim
        font.family: Config.font
        font.pixelSize: 12
    }
}
