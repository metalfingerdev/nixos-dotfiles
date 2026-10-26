import QtQuick

// The island's view slot: a Loader plus the DEFAULT keyboard, for every view.
// Plain QtQuick (no Engine, no Quickshell), so modules/tests/tst_keyboard.qml can drive it.
//
// The Loader is a focus scope. A key goes to the focused item first and bubbles up; whatever the
// view doesn't accept ends up here:
//   Tab / Right / Down     next focusable item in the view (activeFocusOnTab), wrapping
//   Backtab / Left / Up    previous
//   Escape                 cancel() (Bar: Engine.back(), which closes when there is no history)
// Every key that reaches here, and every focus move inside the view, emits activity() (Bar:
// Engine.key(), which restarts the countdown). The same, minus the focus a view gets when it
// loads, emits navigated() (Bar: focus rings show; see Config.focusVisible).
// A view that accepts keys itself reports them the same way (see views/Launcher.qml).
// Enter/Space press the focused Pill (Pill handles that itself).
//
// A view with its own rules handles keys in its Keys handlers; anything it leaves unaccepted
// still gets the defaults. A view that sets `focus: true` on an item keeps that initial focus;
// otherwise its first focusable item gets it.
Loader {
    id: root

    signal cancel()
    signal activity()
    signal navigated()

    // focus that lands this soon after a load is the view settling (the window activating
    // included), not the user moving it
    property double loadedAt: 0
    readonly property int settleMs: 400

    focus: true

    // One handler, not Keys.onTabPressed etc.: Qt skips onPressed for a key that has its own handler,
    // and every key that reaches here must count as activity.
    Keys.onPressed: event => {
        activity()
        navigated()
        switch (event.key) {
        case Qt.Key_Tab: case Qt.Key_Right: case Qt.Key_Down: step(true);  break
        case Qt.Key_Backtab: case Qt.Key_Left: case Qt.Key_Up: step(false); break
        case Qt.Key_Escape: cancel(); break
        default: event.accepted = false
        }
    }

    // Tab on a Pill never gets here: Qt's own activeFocusOnTab navigation takes it. Focus moving
    // inside the view is the user too, so it counts as activity as well.
    Window.onActiveFocusItemChanged: {
        if (!inView(Window.activeFocusItem)) return
        activity()
        if (Date.now() - loadedAt > settleMs) navigated()
    }

    onLoaded: {
        loadedAt = Date.now()
        if (!focusedInside(item)) step(true)
    }

    // inside the loaded view (and not the view's root itself)
    function inView(it) {
        for (let p = it; p; p = p.parent) if (p === item) return it !== item
        return false
    }

    // true = the view already asked for focus somewhere (QML's `focus: true`)
    function focusedInside(it) {
        if (!it) return false
        for (let i = 0; i < it.children.length; i++) {
            const c = it.children[i]
            if (c.focus || focusedInside(c)) return true
        }
        return false
    }

    // Move to the next/previous item with activeFocusOnTab, staying inside the view.
    function step(forward) {
        const current = Window.activeFocusItem
        const from = inView(current) ? current : root
        const next = from.nextItemInFocusChain(forward)
        if (next && next !== from && inView(next)) next.forceActiveFocus()
    }
}
