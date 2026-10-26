import QtQuick

// The island's view slot: a Loader plus the DEFAULT keyboard, for every view.
// Plain QtQuick (no Engine, no Quickshell), so modules/tests/tst_keyboard.qml can drive it.
//
// The Loader is a focus scope. A key goes to the focused item first and bubbles up; whatever the
// view doesn't accept ends up here:
//   Tab / Backtab          next / previous focusable item in the view (activeFocusOnTab), wrapping
//   arrows                 the nearest focusable item that way (so grids and rows work); with
//                          nothing that way, the next (Right/Down) or previous (Left/Up), wrapping
//   a letter, digit or sign   presses the control whose `shortcut` it is (Pill, QuickTile, Tile,
//                          ListEntry, Chip, a Segmented option): they show it as a keycap while the
//                          keyboard is in use
//   Escape, Backspace      cancel() (Bar: Engine.back(), which closes when there is no history)
// Every key that reaches here, and every focus move inside the view, emits activity() (Bar:
// Engine.key(), which restarts the countdown). The same, minus the focus a view gets when it
// loads, emits navigated() (Bar: focus rings show; see Config.focusVisible).
// A view that accepts keys itself reports them the same way (see views/Launcher.qml).
// Enter/Space press the focused control (each control handles that itself).
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
        case Qt.Key_Tab:     step(true);  break
        case Qt.Key_Backtab: step(false); break
        case Qt.Key_Right:   move(1, 0);  break
        case Qt.Key_Left:    move(-1, 0); break
        case Qt.Key_Down:    move(0, 1);  break
        case Qt.Key_Up:      move(0, -1); break
        case Qt.Key_Escape: case Qt.Key_Backspace: cancel(); break
        default: {
            const plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            event.accepted = plain && shortcut(event.text)
        }
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

    // Every focusable item of the view: the window's focus chain, kept to the view.
    function focusables() {
        const out = []
        const first = root.nextItemInFocusChain(true)
        let it = first
        for (let guard = 0; it && guard < 1000; guard++) {
            if (inView(it) && it.visible && it.enabled) out.push(it)
            it = it.nextItemInFocusChain(true)
            if (it === first) break
        }
        return out
    }

    // Arrow keys: the nearest focusable item in direction (dx, dy). "Nearest" is the gap along the
    // axis plus three times the miss across it, so a grid's neighbour beats a closer diagonal.
    // Nothing that way: the next or previous item, as Tab would (and it wraps).
    function move(dx, dy) {
        const current = Window.activeFocusItem
        if (!inView(current)) { step(dx + dy > 0); return }
        const a = current.mapToItem(null, 0, 0, current.width, current.height)
        let best = null, bestScore = Infinity
        for (const it of focusables()) {
            if (it === current) continue
            const b = it.mapToItem(null, 0, 0, it.width, it.height)
            let along, across
            if (dx !== 0) {
                along = dx > 0 ? b.x - (a.x + a.width) : a.x - (b.x + b.width)
                across = Math.max(0, Math.abs((b.y + b.height / 2) - (a.y + a.height / 2)) - (a.height + b.height) / 2)
            } else {
                along = dy > 0 ? b.y - (a.y + a.height) : a.y - (b.y + b.height)
                across = Math.max(0, Math.abs((b.x + b.width / 2) - (a.x + a.width / 2)) - (a.width + b.width) / 2)
            }
            if (along < -4) continue                                  // not that way
            const centre = dx !== 0 ? Math.abs((b.y + b.height / 2) - (a.y + a.height / 2))
                                    : Math.abs((b.x + b.width / 2) - (a.x + a.width / 2))
            const score = Math.max(0, along) + 3 * across + 0.05 * centre
            if (score < bestScore) { best = it; bestScore = score }
        }
        if (best) best.forceActiveFocus()
        else step(dx + dy > 0)
    }

    // A typed character: press the visible, enabled control whose `shortcut` it is.
    function shortcut(text) {
        if (!item || !text || text.length !== 1 || text === " ") return false
        const hit = find(item, text.toLowerCase())
        if (!hit) return false
        if (hit.activeFocusOnTab) hit.forceActiveFocus()
        if (typeof hit.activate === "function") hit.activate()
        else if (typeof hit.press === "function") hit.press()
        return true
    }
    function find(it, key) {
        for (let i = 0; i < it.children.length; i++) {
            const c = it.children[i]
            if (!c.visible || !c.enabled) continue
            if (typeof c.shortcut === "string" && c.shortcut !== "" && c.shortcut.toLowerCase() === key) return c
            const deeper = find(c, key)
            if (deeper) return deeper
        }
        return null
    }
}
