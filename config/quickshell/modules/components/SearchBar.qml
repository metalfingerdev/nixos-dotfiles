import QtQuick

// A search bar (Material 3): a pill with a glyph (`icon`) in a primary circle, the field, then any
// children (filter chips) on the right. A focus scope: `focus: true` on the bar puts the keyboard
// in its field. The field takes its own keys and reports them as signals, so the view decides
// what they do:
//   key()              any keystroke (for Engine.key(): ViewLoader never sees these)
//   accepted()         Enter            up() / down()   arrows, only with `takesArrows` (otherwise
//                                       they move focus out of the field, like Tab)
//   tab(backward)      Tab / Backtab, only with `takesTab` (otherwise Tab moves focus as usual)
//   escaped()          Escape           backspaceEmpty()  Backspace on an empty field
// With `readOnly` it's a button that looks like a field: clicked() on a click.
FocusScope {
    id: root

    property alias text: field.text
    property alias field: field
    property string placeholder: "Search"
    property string icon: "search"
    property bool readOnly: false
    property bool takesTab: false
    property bool takesArrows: false
    property int fieldSize: 16
    default property alias trailing: side.data

    signal key()
    signal accepted()
    signal up()
    signal down()
    signal tab(bool backward)
    signal escaped()
    signal backspaceEmpty()
    signal clicked()

    implicitWidth: 400
    implicitHeight: 56

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Config.state(Config.high, Config.text, area.containsMouse && root.readOnly, false)
        border.width: field.activeFocus && !root.readOnly ? 2 : 0
        border.color: Config.primary
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.readOnly ? Qt.PointingHandCursor : Qt.IBeamCursor
        onClicked: root.readOnly ? root.clicked() : field.forceActiveFocus()
    }

    Rectangle {
        id: badge
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        width: root.height - 12
        height: width
        radius: width / 2
        color: Config.primary

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: Math.round(root.height * 0.36)
            color: Config.primaryInk
        }
    }

    TextInput {
        id: field
        anchors { left: badge.right; leftMargin: 12; right: side.left; rightMargin: 10; top: parent.top; bottom: parent.bottom }
        focus: true
        verticalAlignment: TextInput.AlignVCenter
        readOnly: root.readOnly
        activeFocusOnTab: !root.readOnly
        color: Config.text
        selectionColor: Config.secondary
        selectedTextColor: Config.secondaryInk
        font.family: Config.font
        font.pixelSize: root.fieldSize
        clip: true

        Keys.onPressed: event => {
            root.key()
            switch (event.key) {
            case Qt.Key_Return: case Qt.Key_Enter: root.accepted(); break
            case Qt.Key_Up: case Qt.Key_Down:
                if (!root.takesArrows) { event.accepted = false; return }
                if (event.key === Qt.Key_Up) root.up(); else root.down()
                break
            case Qt.Key_Escape:  root.escaped(); break
            case Qt.Key_Tab: case Qt.Key_Backtab:
                if (!root.takesTab) { event.accepted = false; return }
                root.tab(event.key === Qt.Key_Backtab); break
            case Qt.Key_Backspace:
                if (text.length > 0) { event.accepted = false; return }
                root.backspaceEmpty(); break
            default: event.accepted = false; return
            }
            event.accepted = true
        }

        Text {
            visible: field.text === ""
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            elide: Text.ElideRight
            text: root.placeholder
            color: Config.dim
            font: field.font
        }
    }

    Row {
        id: side
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 6
    }
}
