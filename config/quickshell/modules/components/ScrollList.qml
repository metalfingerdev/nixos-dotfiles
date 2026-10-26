import QtQuick

// A vertical list that grows with its rows up to `maxHeight`, then scrolls (wheel or drag).
// Children stack like a Column. Keyboard focus moving to a row out of sight scrolls it into view.
Flickable {
    id: root

    property real maxHeight: 300
    property alias spacing: column.spacing
    default property alias rows: column.data

    implicitHeight: Math.min(column.implicitHeight, maxHeight)
    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: column
        width: root.width
    }

    function reveal(item) {
        for (let p = item; p; p = p.parent) {
            if (p === column) {
                const y = item.mapToItem(column, 0, 0).y
                if (y < contentY) contentY = y
                else if (y + item.height > contentY + height) contentY = y + item.height - height
                return
            }
        }
    }
    Window.onActiveFocusItemChanged: if (Window.activeFocusItem) reveal(Window.activeFocusItem)
}
