import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.taskbar

// Resting view: shown on hover (Peek) and when clicked (Pinned).
FocusScope {
    id: root

    Component.onCompleted: root.forceActiveFocus()
    onVisibleChanged: {
        if (visible) root.forceActiveFocus()
    }

    implicitWidth: 1080
    implicitHeight: 72

    // Allows the parent window to know if keyboard routing is active
    property bool keyboardActive: false
    readonly property bool engaged: keyboardActive

    // Track active selection index for keyboard arrow navigation across the pills
    property int currentIndex: 0

    focus: true


    Keys.onPressed: (event) => {
        keyboardActive = true
        // Only target children that have our custom itemIndex property (excludes clock)
        let pills = rowLayout.children.filter(child => child.hasOwnProperty("itemIndex"))

        if (pills.length === 0) return

        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            currentIndex = (currentIndex - 1 + pills.length) % pills.length
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            currentIndex = (currentIndex + 1) % pills.length
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentIndex >= 0 && currentIndex < pills.length) {
                let targetPill = pills[currentIndex]
                if (targetPill && typeof targetPill.triggered === "function") {
                    targetPill.triggered()
                }
            }
            event.accepted = true
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 16

        Text {
            property int itemIndex: 0
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: (keyboardActive && root.currentIndex === itemIndex) ? "#3a86ff" : "#f7f7f7"
            font.pixelSize: 22
            function triggered() {
                // Optional: Action when Enter is pressed on the clock
            }
        }

        Pill {
            property int itemIndex: 1
            anchors.verticalCenter: parent.verticalCenter
            text: "workspaces"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: {
                keyboardActive = false
                IslandState.send(IslandState.Event.Open, IslandState.View.Workspaces)
            }
            function triggered() { clicked() }
        }

        Pill {
            property int itemIndex: 2
            anchors.verticalCenter: parent.verticalCenter
            text: "launcher"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: {
                keyboardActive = false
                IslandState.send(IslandState.Event.Open, IslandState.View.Launcher)
            }
            function triggered() { clicked() }
        } 

        Pill {
            property int itemIndex: 3
            anchors.verticalCenter: parent.verticalCenter
            text: "dashboard"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: {
                keyboardActive = false
                IslandState.send(IslandState.Event.Open, IslandState.View.Dashboard)
            }
            function triggered() { clicked() }
        }    

        Pill {
            property int itemIndex: 4
            anchors.verticalCenter: parent.verticalCenter
            text: "media"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: {
                keyboardActive = false
                IslandState.send(IslandState.Event.Open, IslandState.View.Media)
            }
            function triggered() { clicked() }
        }

        Pill {
            property int itemIndex: 5
            anchors.verticalCenter: parent.verticalCenter
            text: "notify"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: {
                keyboardActive = false
                IslandState.send(IslandState.Event.Open, IslandState.View.Notify)
            }
            function triggered() { clicked() }
        }

        Pill {
            property int itemIndex: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "theme"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: {
                keyboardActive = false
                IslandState.send(IslandState.Event.Open, IslandState.View.Theme)
            }
            function triggered() { clicked() }
        }

        Pill {
            property int itemIndex: 7
            text: "bluetooth"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: {
                keyboardActive = false
                IslandState.send(IslandState.Event.Open, IslandState.View.Bluetooth)
            }
            function triggered() { clicked() }
        }

        Pill {
            property int itemIndex: 8
            text: "network"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: keyboardActive = false
            function triggered() { clicked() }
        }

        Pill {
            property int itemIndex: 9
            text: "power"
            keyboardSelected: keyboardActive && (root.currentIndex === itemIndex)
            onClicked: keyboardActive = false
            function triggered() { clicked() }
        }
    }
}