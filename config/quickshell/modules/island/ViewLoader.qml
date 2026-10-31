import QtQuick

// Plain QtQuick (no Engine, no Quickshell), so modules/tests/tst_keyboard.qml can drive it.
//
// A key goes to the focused item first and bubbles up, so a view overrides any default by accepting
// the key. Every key that reaches here and every focus move inside the view restarts the countdown
// (activity); a view that accepts keys itself must report them too (see views/Launcher.qml).
Loader {
    id: root

    signal cancel()
    signal back()
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
        case Qt.Key_Right:   if (!nudge(1)) move(1, 0);   break
        case Qt.Key_Left:    if (!nudge(-1)) move(-1, 0); break
        case Qt.Key_Down:    move(0, 1);  break
        case Qt.Key_Up:      move(0, -1); break
        case Qt.Key_Escape:    cancel(); break
        case Qt.Key_Backspace: back(); break
        case Qt.Key_Return:
        case Qt.Key_Enter:   event.accepted = press(false); break
        case Qt.Key_Space:   event.accepted = press(true);  break
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

    function inView(it) {
        for (let p = it; p; p = p.parent) if (p === item) return it !== item
        return false
    }

    function focusedInside(it) {
        if (!it) return false
        for (let i = 0; i < it.children.length; i++) {
            const c = it.children[i]
            if (c.focus || focusedInside(c)) return true
        }
        return false
    }

    function step(forward) {
        const current = Window.activeFocusItem
        const from = inView(current) ? current : root
        const next = from.nextItemInFocusChain(forward)
        if (next && next !== from && inView(next)) next.forceActiveFocus()
    }

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

    // "Nearest" is the gap along the axis plus three times the miss across it, so a grid's neighbour beats
    // a closer diagonal.
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
            if (along < -4) continue
            const centre = dx !== 0 ? Math.abs((b.y + b.height / 2) - (a.y + a.height / 2))
                                    : Math.abs((b.x + b.width / 2) - (a.x + a.width / 2))
            const score = Math.max(0, along) + 3 * across + 0.05 * centre
            if (score < bestScore) { best = it; bestScore = score }
        }
        if (best) best.forceActiveFocus()
        else step(dx + dy > 0)
    }

    // Here, not in each control: a handler on the control accepts the key, so it never reaches this
    // Loader and doesn't count as activity, and a pinned view timed out while it was being used.
    // press() is what Enter does where it differs from Space (a tile's Enter opens, its Space switches).
    function press(space) {
        const it = Window.activeFocusItem
        if (!inView(it)) return false
        if (!space && typeof it.press === "function") it.press()
        else if (typeof it.activate === "function") it.activate()
        else return false
        return true
    }
    function nudge(dir) {
        const it = Window.activeFocusItem
        if (!inView(it) || typeof it.nudge !== "function") return false
        it.nudge(dir)
        return true
    }

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
