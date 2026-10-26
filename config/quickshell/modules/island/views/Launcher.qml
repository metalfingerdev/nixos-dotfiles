import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components

// Search field + up to `maxResults` desktop entries, best match first.
// Ranking: the name starts with the query > a word in the name does > the name contains it >
// its generic name or keywords contain it ("browser" finds Firefox) > the name has the query's
// letters in order ("ffx" finds Firefox). Ties go to the shorter name.
// Custom keys (the rest fall through to ViewLoader): type to filter, Up/Down to select, Enter to
// launch, Escape to close, Backspace on an empty field to go back. The field keeps focus; the
// pointer only takes the selection when it actually moves.
// Terminal apps (Terminal=true) open in kitty.
Item {
    id: root

    readonly property int maxResults: 6
    readonly property string terminal: "kitty"
    property int selected: 0

    // 0 = no match; higher = better
    function score(app, q) {
        const name = app.name.toLowerCase()
        if (name.startsWith(q)) return 500
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 400
        if (name.includes(q)) return 300
        const extra = [app.genericName ?? "", String(app.keywords ?? ""), app.id ?? ""].join(" ").toLowerCase()
        if (extra.includes(q)) return 200
        let i = 0
        for (const c of name) if (c === q[i]) i++
        return i === q.length ? 100 : 0
    }

    readonly property var matches: {
        const q = search.text.trim().toLowerCase()
        if (q === "") return []
        return Array.from(DesktopEntries.applications.values)
            .filter(a => !a.noDisplay)
            .map(a => ({ app: a, score: root.score(a, q) }))
            .filter(m => m.score > 0)
            .sort((a, b) => (b.score - a.score) || (a.app.name.length - b.app.name.length))
            .slice(0, root.maxResults)
            .map(m => m.app)
    }
    onMatchesChanged: selected = 0

    function launch(entry) {
        if (!entry) return
        if (entry.runInTerminal)
            Quickshell.execDetached({ command: [terminal, "-e"].concat(entry.command), workingDirectory: entry.workingDirectory })
        else
            entry.execute()
        Engine.close()
    }

    implicitWidth: 520
    // margins + search field + one (spacing + row) per match
    implicitHeight: 16 + 36 + matches.length * (6 + 34) + 16

    ColumnLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Config.innerRadius
            color: Config.raised

            Icon {
                id: glass
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                name: "search"
                size: 18
                color: Config.dim
            }

            TextInput {
                id: search
                anchors { left: glass.right; leftMargin: 8; right: backPill.left; rightMargin: 8; top: parent.top; bottom: parent.bottom }
                verticalAlignment: TextInput.AlignVCenter
                color: Config.text
                font.family: Config.font
                font.pixelSize: 14
                clip: true
                focus: true

                // the field accepts its keys, so ViewLoader never sees them: report the keystroke here
                Keys.onPressed: event => {
                    Engine.key()
                    if (event.key === Qt.Key_Backspace && text.length === 0) { Engine.back(); event.accepted = true }
                    else event.accepted = false
                }
                Keys.onDownPressed:   root.selected = root.matches.length ? (root.selected + 1) % root.matches.length : 0
                Keys.onUpPressed:     root.selected = root.matches.length ? (root.selected - 1 + root.matches.length) % root.matches.length : 0
                Keys.onReturnPressed: root.launch(root.matches[root.selected])
                Keys.onEnterPressed:  root.launch(root.matches[root.selected])
                Keys.onEscapePressed: Engine.close()

                Text {
                    visible: search.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search applications"
                    color: Config.faint
                    font: search.font
                }
            }

            Pill {
                id: backPill
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                text: "back"
                activeFocusOnTab: false
                onClicked: Engine.back()
            }
        }

        Repeater {
            model: root.matches

            Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: index === root.selected

                Layout.fillWidth: true
                implicitHeight: 34
                radius: Config.innerRadius
                color: current ? Config.selected : "transparent"

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 10

                    IconImage {
                        implicitSize: 22
                        asynchronous: true
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        elide: Text.ElideRight
                        color: row.current ? Config.text : Config.dim
                        font.family: Config.font
                        font.pixelSize: Config.body
                        font.weight: row.current ? Font.DemiBold : Font.Normal
                    }
                    Text {
                        visible: text !== ""
                        text: row.modelData.genericName ?? ""
                        elide: Text.ElideRight
                        Layout.maximumWidth: 180
                        color: Config.faint
                        font.family: Config.font
                        font.pixelSize: Config.small
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    property point last: Qt.point(-1, -1)
                    // only a real move takes the selection: a pointer resting where a row appears
                    // under it must not fight the keyboard
                    onPositionChanged: mouse => {
                        const p = mapToGlobal(mouse.x, mouse.y)
                        if (Math.abs(p.x - last.x) > 0.5 || Math.abs(p.y - last.y) > 0.5) {
                            if (last.x >= 0) root.selected = row.index
                            last = p
                        }
                    }
                    onClicked: root.launch(row.modelData)
                }
            }
        }
    }
}
