import QtQuick

// `inset` from every edge, so focus rings (drawn just outside a row) aren't clipped.
Flickable {
    id: root

    property real maxHeight: 300
    property real inset: 7
    property alias spacing: column.spacing
    readonly property real innerWidth: width - 2 * inset
    default property alias rows: column.data

    implicitHeight: Math.min(column.implicitHeight + 2 * inset, maxHeight)
    contentWidth: width
    contentHeight: column.implicitHeight + 2 * inset
    clip: true
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: column
        x: root.inset
        y: root.inset
        width: root.innerWidth
    }

    // A row focused while the list was still being laid out may have scrolled it for a height it
    // didn't keep: keep the scroll inside what there is to scroll.
    function settle() { contentY = Math.max(0, Math.min(contentY, contentHeight - height)) }
    onHeightChanged: settle()
    onContentHeightChanged: settle()

    function reveal(item) {
        for (let p = item; p; p = p.parent) {
            if (p === column) {
                const y = item.mapToItem(column, 0, 0).y
                if (y < contentY) contentY = y
                else if (y + item.height + 2 * inset > contentY + height) contentY = y + item.height + 2 * inset - height
                return
            }
        }
    }
    Window.onActiveFocusItemChanged: if (Window.activeFocusItem) reveal(Window.activeFocusItem)
}
