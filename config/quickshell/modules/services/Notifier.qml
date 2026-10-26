pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Owns every notification until it is dismissed. Knows nothing about the island.
// Behaves like dunst:
//   - every popup has its own countdown: the app's expire_timeout if it sent one (0 = sticky),
//     else the urgency default. Critical defaults to sticky.
//   - only the first maxPopups popups count down; the rest wait their turn ("+N more").
//   - a popup that times out or is closed is not gone: it stays in `items` (dunst's history, our
//     notification center) until dismissed. Transient notifications skip the history.
//   - identical notifications stack into one entry with a count.
//   - replaces_id updates the entry in place and pops it up again.
//
// items:  newest first. Plain objects { id, ref, critical, popup, count, time }.
//         Text, icons and actions are read live from `ref` (the Quickshell Notification).
// popups: the items still showing as popups, critical first, then newest.
Singleton {
    id: root

    // ---- config (dunst defaults) ----
    property int lowMs: 10000
    property int normalMs: 10000
    property int criticalMs: 0              // 0 = stays until closed
    property int maxPopups: 3               // the rest wait, shown as "+N more"
    property bool stackDuplicates: true

    // true = popup countdowns are frozen. Set by whoever shows the popups (hovered, or not on screen).
    property bool held: false

    property var items: []
    readonly property int count: items.length
    readonly property var popups: items.filter(i => i.popup && i.critical)
                                       .concat(items.filter(i => i.popup && !i.critical))

    signal received(bool critical)

    // id -> ms left on that popup's countdown; absent = sticky. Mutated in place on purpose:
    // ticking must not rebuild the views.
    property var left: ({})

    function find(id) { return items.find(i => i.id === id) ?? null }

    function timeoutFor(n) {
        const t = n.expireTimeout               // ms, as sent over D-Bus; 0 = never; -1 = "server default"
        if (t > 0)   return Math.round(t)
        if (t === 0) return 0
        if (n.urgency === NotificationUrgency.Critical) return criticalMs
        return n.urgency === NotificationUrgency.Low ? lowMs : normalMs
    }

    function same(a, b) {
        return a.appName === b.appName && a.summary === b.summary
            && a.body === b.body && a.urgency === b.urgency
    }

    function entry(n, popup, count) {
        return { id: n.id, ref: n, critical: n.urgency === NotificationUrgency.Critical,
                 popup: popup, count: count, time: Date.now() }
    }

    function watch(n) {
        n.closed.connect(() => root.remove(n.id))       // the app closed it, or we dismissed/expired it
        n.summaryChanged.connect(() => root.add(n))     // replaced in place (replaces_id)
        n.bodyChanged.connect(() => root.add(n))
    }

    // New, replaced or popped from history: to the top, popping up, with a fresh countdown.
    function add(n) {
        const prev = find(n.id)
        const dup = stackDuplicates ? (items.find(i => i.id !== n.id && same(i.ref, n)) ?? null) : null
        const ms = timeoutFor(n)
        if (ms > 0) left[n.id] = ms; else delete left[n.id]
        if (dup) delete left[dup.id]

        const e = entry(n, true, dup ? dup.count + 1 : (prev ? prev.count : 1))
        items = [e].concat(items.filter(i => i.id !== n.id && i !== dup))
        if (dup) dup.ref.dismiss()                      // dunst keeps one entry and counts the rest
        if (!prev) watch(n)
        received(e.critical)
    }

    function remove(id) { delete left[id]; items = items.filter(i => i.id !== id) }

    // Gone for good, and the app is told.
    function dismiss(id) {
        const i = find(id)
        remove(id)
        if (i) i.ref.dismiss()
    }

    function dismissAll() {
        const all = items
        left = {}
        items = []
        all.forEach(i => i.ref.dismiss())
    }

    // A popup is over (timed out, or closed by the user): it moves to the history.
    function hide(ids) {
        ids.forEach(id => delete left[id])
        const transient = items.filter(i => ids.includes(i.id) && i.ref.transient)
        items = items.map(i => ids.includes(i.id) ? Object.assign({}, i, { popup: false }) : i)
        transient.forEach(i => i.ref.expire())          // -> closed -> remove
    }

    function close(id) { hide([id]) }
    function closeAll() { hide(popups.map(i => i.id)) }

    // Run an action ("default" = the body was clicked). Not resident = it is done afterwards.
    function invoke(id, identifier) {
        const i = find(id)
        const a = i ? Array.from(i.ref.actions).find(a => a.identifier === identifier) : null
        if (!a) return
        const resident = i.ref.resident
        a.invoke()
        if (!resident && find(id)) dismiss(id)
    }

    // dunst's history-pop: the newest closed notification pops up again.
    function pop() {
        const i = items.find(i => !i.popup)
        if (i) add(i.ref)
    }

    Timer {
        interval: 100
        repeat: true
        running: !root.held && root.popups.slice(0, root.maxPopups).some(i => root.left[i.id] !== undefined)
        onTriggered: {
            const done = []
            root.popups.slice(0, root.maxPopups).forEach(i => {
                if (root.left[i.id] === undefined) return
                root.left[i.id] -= interval
                if (root.left[i.id] <= 0) done.push(i.id)
            })
            if (done.length > 0) root.hide(done)
        }
    }

    NotificationServer {
        id: server
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true                            // keep it alive after this handler returns
            root.add(n)
        }
    }

    // Hot reload keeps tracked notifications on the server: put them back in the history, quietly.
    Component.onCompleted: {
        const kept = server.trackedNotifications.values.slice().reverse()
        kept.forEach(n => root.watch(n))
        items = kept.map(n => root.entry(n, false, 1))
    }

    // dunstctl-style:  qs ipc call notifications close | closeAll | action | pop | clear
    IpcHandler {
        target: "notifications"

        function close(): void    { const p = root.popups[0]; if (p) root.close(p.id) }
        function closeAll(): void { root.closeAll() }
        function action(): void   { const p = root.popups[0]; if (p) root.invoke(p.id, "default") }
        function pop(): void      { root.pop() }
        function clear(): void    { root.dismissAll() }
    }
}
