// BarState.qml
pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property int normal:  0
    readonly property int peeking: 1
    readonly property int hidden:  2

    property int mode: normal

    property string currentView: "tabs"
    property string viewKind:    "tabs"
    property real originX: 0
    property int showBarViewTick: 0

    readonly property bool autohide:           mode === peeking || mode === hidden
    readonly property bool isHidden:           mode === hidden
    readonly property bool isExpanded:         viewKind === "island"
    readonly property bool catchOutsideClicks: isExpanded
    readonly property bool shouldHide:         (mode === peeking && !hovered) && (viewKind === "tabs" || viewKind === "bar")

    property bool hovered: false

    function collapse() {
        viewKind    = "tabs"
        currentView = "tabs"
        originX     = 0
    }

    function wake() {
        if (mode === hidden) mode = peeking
    }

    function transition(event) {
        switch (mode) {

        case normal:
            if (event === "surfaceClick")   { if (isExpanded) collapse() }
            if (event === "outsideClick")   { collapse() }
            if (event === "toggleAutohide") { mode = peeking }
            break

        case peeking:
            if      (event === "hover")          { hovered = true }
            else if (event === "unhover")        { hovered = false }
            else if (event === "surfaceClick")   { if (isExpanded) collapse(); else mode = hidden }
            else if (event === "outsideClick")   { collapse() }
            else if (event === "toggleAutohide") { mode = normal }
            else if (event === "toggleHidden")   { mode = hidden }
            break

        case hidden:
            if (event === "hover")          { mode = peeking; hovered = true }
            if (event === "unhover")        { hovered = false }
            if (event === "toggleHidden")   { mode = peeking }
            if (event === "toggleAutohide") { mode = normal }
            break
        }
    }

    function changeView(viewName, kind, X, W) {
        wake()
        currentView = viewName
        viewKind    = kind
        originX     = X - W / 2
    }

    function showBarView(viewName) {
        wake()
        currentView      = viewName
        viewKind         = "bar"
        showBarViewTick += 1
    }

    function toggleHidden()   { transition("toggleHidden") }
    function toggleAutohide() { transition("toggleAutohide") }
}