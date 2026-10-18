pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Owns every notification until the user dismisses it. Knows nothing about the island.
// items: newest first. Each is a plain object:
//   { id, ref, appName, summary, body, appIcon, image, critical, toast }
//   toast = "recently arrived", used by the transient view. Critical ones never lose it.
Singleton {
    id: root

    property var items: []
    readonly property int count: items.length

    signal received(bool critical)

    function remove(id) { items = items.filter(i => i.id !== id) }

    function dismiss(id) {
        const n = items.find(i => i.id === id)
        remove(id)
        if (n) n.ref.dismiss()          // tells the sending app it was closed
    }

    function dismissAll() {
        const all = items
        items = []
        all.forEach(i => i.ref.dismiss())
    }

    // After a quiet period, non-critical notifications stop being toasts.
    Timer {
        id: quiet
        interval: 4000
        onTriggered: root.items = root.items.map(
            i => i.critical ? i : Object.assign({}, i, { toast: false }))
    }

    NotificationServer {
        bodySupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true            // keep it alive after this handler returns
            const critical = n.urgency === NotificationUrgency.Critical

            root.items = [{
                id: n.id, ref: n,
                appName: n.appName, summary: n.summary, body: n.body,
                appIcon: n.appIcon, image: n.image,
                critical: critical, toast: true
            }].concat(root.items)

            n.closed.connect(() => root.remove(n.id))   // the app closed it itself
            quiet.restart()
            root.received(critical)
        }
    }
}