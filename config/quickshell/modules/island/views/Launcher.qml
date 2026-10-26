import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.island
import qs.modules.components

// Search field + up to `maxResults` matching desktop entries.
// Custom keys (the rest fall through to Bar's defaults): type to filter, Up/Down to select,
// Enter to launch, Escape to close. The field keeps focus; result rows are mouse/selection only.
Item {
    id: root

    readonly property int maxResults: 5
    property int selected: 0

    readonly property var matches: {
        const q = search.text.trim().toLowerCase()
        const out = []
        if (q === "") return out
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length && out.length < maxResults; i++) {
            const a = apps[i]
            if (!a.noDisplay && a.name.toLowerCase().includes(q)) out.push(a)
        }
        return out
    }
    onMatchesChanged: selected = 0

    function launch(entry) {
        if (!entry) return
        entry.execute()
        Engine.close()
    }

    implicitWidth: 520
    // margins + search field + one (spacing + row) per match
    implicitHeight: 16 + 36 + matches.length * (8 + 28) + 16

    ColumnLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 8
            color: "#1a1a1a"

            TextInput {
                id: search
                anchors { fill: parent; leftMargin: 12; rightMargin: backPill.width + 12 }
                verticalAlignment: TextInput.AlignVCenter
                color: "#f7f7f7"
                font.pixelSize: 14
                clip: true
                focus: true


                // the field accepts its keys, so ViewLoader never sees them: report the keystroke here
                Keys.onPressed: event => { Engine.key(); event.accepted = false }
                Keys.onDownPressed:   root.selected = Math.min(root.selected + 1, root.matches.length - 1)
                Keys.onUpPressed:     root.selected = Math.max(root.selected - 1, 0)
                Keys.onReturnPressed: root.launch(root.matches[root.selected])
                Keys.onEnterPressed:  root.launch(root.matches[root.selected])
                Keys.onEscapePressed: Engine.close()

                Text {
                    visible: search.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search applications"
                    color: "#6a6a72"
                    font: search.font
                }
            }

            Pill {
                id: backPill
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                text: "back"
                onClicked: Engine.back()
            }
        }

        Repeater {
            model: root.matches

            Pill {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                text: modelData.name
                keyboardSelected: index === root.selected
                activeFocusOnTab: false             // Up/Down select; focus stays in the field
                onClicked: root.launch(modelData)
            }
        }
    }

}