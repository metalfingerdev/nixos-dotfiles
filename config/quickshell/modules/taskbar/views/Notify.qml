import QtQuick
import Quickshell.Widgets
import qs.modules.services
import qs.modules.taskbar

// Transient: recent toasts. Pinned: everything, dismissable.
FocusScope {
    id: root

    Component.onCompleted: root.forceActiveFocus()
    onVisibleChanged: {
        if (visible) root.forceActiveFocus()
    }

    property bool keyboardActive: false
    readonly property bool engaged: keyboardActive

    Keys.onPressed: (event) => {
        keyboardActive = true
            if (event.key === Qt.Key_Backspace ) {
                IslandState.send(IslandState.Event.Back)
                event.accepted = true
            } else {
                event.accepted = false
            }
    }

    signal closeRequested

    readonly property bool pinned: IslandState.pinned
    readonly property var list: pinned ? Notifier.items : Notifier.items.filter(n => n.toast)
    readonly property int maxRows: pinned ? 6 : 4
    readonly property var rows: list.slice(0, maxRows)

    readonly property int rowH: 52
    readonly property int headerH: pinned ? 40 : 0
    readonly property int bodyH: rows.length > 0 ? rows.length * rowH : 40
    readonly property int moreH: list.length > maxRows ? 24 : 0

    implicitWidth: 380
    implicitHeight: headerH + bodyH + moreH + 8      // the island morphs to this

    onRowsChanged: {
        if (!pinned && rows.length === 0 && IslandState.view === IslandState.View.Notify) {
            closeRequested()
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !IslandState.keyboard
        onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Notify)
    }

    // ---- header (pinned only) ----
    Item {
        visible: root.pinned
        width: root.width
        height: root.headerH

        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: Notifier.count === 1 ? "1 notification" : Notifier.count + " notifications"
            color: "#f7f7f7"
            font.pixelSize: 13
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Pill { text: "clear"; onClicked: Notifier.dismissAll() }
            Pill { text: "back";  onClicked: IslandState.send(IslandState.openHome()) }
        }
    }

    // ---- rows: newest on top, older pushed down ----
    Column {
        y: root.headerH
        width: root.width

        Repeater {
            model: root.rows

            delegate: Item {
                required property var modelData
                width: root.width
                height: root.rowH

                Row {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Item {
                        width: 28; height: 28
                        anchors.verticalCenter: parent.verticalCenter

                        IconImage {
                            anchors.fill: parent
                            source: modelData.appIcon
                            visible: modelData.image === ""
                        }
                        Image {
                            anchors.fill: parent
                            source: modelData.image
                            fillMode: Image.PreserveAspectFit
                            visible: modelData.image !== ""
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.width - 120

                        Text {
                            width: parent.width
                            text: modelData.summary
                            elide: Text.ElideRight
                            color: modelData.critical ? "#ff6b6b" : "#f7f7f7"
                            font.pixelSize: 14
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: modelData.body
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: "#9a9a9a"
                            font.pixelSize: 12
                        }
                    }

                    Pill {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "x"
                        onClicked: Notifier.dismiss(modelData.id)
                    }
                }
            }
        }
    }

    Text {
        visible: root.pinned && root.rows.length === 0
        x: 16; y: root.headerH + 10
        text: "No notifications"
        color: "#9a9a9a"
        font.pixelSize: 13
    }

    Text {
        visible: root.moreH > 0
        x: 16; y: root.headerH + root.bodyH + 2
        text: "+" + (root.list.length - root.maxRows) + " more"
        color: "#9a9a9a"
        font.pixelSize: 12
    }
}