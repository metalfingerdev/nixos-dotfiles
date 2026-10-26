import QtQuick

// The back button every view uses: a round tonal button with the back arrow, to the view that was
// open before. Backspace and the mouse's back button do the same; Escape closes everything. Out
// of the Tab order: Backspace is quicker.
Pill {
    icon: Config.symbol.back
    iconSize: 22
    implicitHeight: 44
    activeFocusOnTab: false
}
