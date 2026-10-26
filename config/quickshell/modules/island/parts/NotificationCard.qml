import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.components
import qs.modules.services

// One notification as a card (Material 3): the app's icon in a circle, "app · time", the summary,
// up to two lines of body, its named actions, and a close button. A critical one has a red edge.
//   center: true   (the notification center) click or Enter: default action, x or Delete: dismiss.
//                  Focusable: Tab/arrows reach it
//   center: false  (a popup) left click: close it (it stays in the center), middle: default action,
//                  right: close all, x: close
Rectangle {
    id: root

    required property var modelData          // a Notifier item: { id, ref, critical, count, time }
    property bool center: true
    readonly property var n: modelData.ref

    function iconFor(name) {
        if (!name) return ""
        if (name.startsWith("/")) return "file://" + name
        if (name.includes("://")) return name
        return Quickshell.iconPath(name, true)
    }
    function ago(t) {
        const m = Math.floor((Date.now() - t) / 60000)
        return m < 1 ? "now" : m < 60 ? m + " min" : Qt.formatTime(new Date(t), "HH:mm")
    }

    activeFocusOnTab: center
    Keys.onReturnPressed: Notifier.invoke(modelData.id, "default")
    Keys.onEnterPressed:  Notifier.invoke(modelData.id, "default")
    Keys.onDeletePressed: Notifier.dismiss(modelData.id)

    implicitWidth: 420
    implicitHeight: Math.max(72, column.implicitHeight + 32)
    radius: Config.innerRadius + 4
    color: Config.state(Config.container, Config.text, area.containsMouse, area.pressed || (activeFocus && Config.focusVisible))
    border.width: modelData.critical ? 1 : 0
    border.color: Config.bad
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            const id = root.modelData.id
            if (root.center || mouse.button === Qt.MiddleButton) Notifier.invoke(id, "default")
            else if (mouse.button === Qt.RightButton) Notifier.closeAll()
            else Notifier.close(id)
        }
    }

    ClippingRectangle {
        id: badge
        x: 16; y: 16
        width: 40
        height: 40
        radius: 20
        color: Config.high

        Image {
            id: picture
            anchors.fill: parent
            source: root.n?.image ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: source != "" && status === Image.Ready
        }
        IconImage {
            id: appIcon
            anchors { fill: parent; margins: 6 }
            source: root.iconFor(root.n?.appIcon ?? "")
            visible: !picture.visible && source != ""
        }
        Icon {
            anchors.centerIn: parent
            visible: !picture.visible && !appIcon.visible
            name: root.modelData.critical ? "priority_high" : "notifications"
            size: 20
            filled: true
            color: root.modelData.critical ? Config.bad : Config.primary
        }
    }

    Column {
        id: column
        anchors { left: badge.right; leftMargin: 14; right: close.left; rightMargin: 6; top: parent.top; topMargin: 15 }
        spacing: 2

        Text {
            width: parent.width
            text: (root.n?.appName || "Notification") + "  ·  " + root.ago(root.modelData.time)
            elide: Text.ElideRight
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.small
        }
        Text {
            width: parent.width
            text: (root.n?.summary ?? "") + (root.modelData.count > 1 ? "  (" + root.modelData.count + ")" : "")
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: root.modelData.critical ? Config.bad : Config.text
            font.family: Config.font
            font.pixelSize: Config.body + 1
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: root.n?.body ?? ""
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.small + 1
        }

        // named actions (the default one is the click on the card)
        Row {
            readonly property var actions: Array.from(root.n?.actions ?? []).filter(a => a.identifier !== "default").slice(0, 2)
            visible: actions.length > 0
            topPadding: 6
            spacing: 6

            Repeater {
                model: parent.actions
                delegate: Pill {
                    required property var modelData
                    implicitHeight: 36
                    text: modelData.text
                    onClicked: Notifier.invoke(root.modelData.id, modelData.identifier)
                }
            }
        }
    }

    Pill {
        id: close
        anchors { right: parent.right; rightMargin: 8; top: parent.top; topMargin: 8 }
        kind: "text"
        icon: "close"
        iconSize: 20
        implicitHeight: 36
        activeFocusOnTab: false
        onClicked: root.center ? Notifier.dismiss(root.modelData.id) : Notifier.close(root.modelData.id)
    }

    FocusRing {}
}
