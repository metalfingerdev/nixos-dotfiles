import QtQuick

// Pure visuals: the shape, plus whichever view the state asks for.
// Views declare their own implicitWidth/Height; the shape morphs to match.
Item {
    id: root

    readonly property int handleW: 120     // collapsed bump (only when space is NOT reserved)
    readonly property int handleH: 4

    // ---- appearance per mode: the only place that knows what Pill vs Notch means ----
    readonly property bool floating: IslandState.mode === IslandState.Mode.Pill
    readonly property int topGap: floating ? 8 : 0          // Offset applied inside Bar.qml's hit area
    readonly property int reservedH: IslandState.compactHeight + topGap   // exclusive zone when space is on

    // -1 = nothing to show (collapsed handle). `shown` is what is actually loaded,
    // it lags `target` by the fade-out so views swap while invisible.
    readonly property int target: {
        if (IslandState.phase !== IslandState.Phase.Collapsed) return IslandState.view
        return IslandState.space ? IslandState.View.Compact : -1
    }
    property int shown: -1

    readonly property bool open: target !== -1
    readonly property real bodyW: open && loader.item ? loader.item.implicitWidth  : handleW
    readonly property real bodyH: open && loader.item ? loader.item.implicitHeight : handleH

    width: body.width
    height: body.height

    Component.onCompleted: shown = target      // a binding change never fires for the initial value

    onTargetChanged: swap.restart()

    function syncEngaged() {
        IslandState.send(loader.item?.engaged === true ? IslandState.Event.Engage
                                                       : IslandState.Event.Release)
    }

    SequentialAnimation {
        id: swap
        NumberAnimation { target: loader; property: "opacity"; to: 0; duration: root.shown === -1 ? 0 : 90 }
        ScriptAction    { script: root.shown = root.target }
        NumberAnimation { target: loader; property: "opacity"; to: 1; duration: 140 }
    }

    Rectangle {
        id: body

        readonly property real r: Math.min(height * 0.4, 20)

        width: root.bodyW
        height: root.bodyH

        color: "#000000"
        radius: 0
        topLeftRadius:     root.floating ? r : 0     // Notch: sharp top (attached). Island: floating pill.
        topRightRadius:    root.floating ? r : 0
        bottomLeftRadius:  r
        bottomRightRadius: r
        clip: true

        Behavior on width  { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        // Fixed-size view, centred at the top. The body only *reveals* it as it grows,
        // so content never gets squished mid-animation.
        Loader {
            id: loader
            anchors.horizontalCenter: parent.horizontalCenter
            active: root.shown !== -1
            source: root.shown === -1 ? "" : Registry.get(root.shown).url

            onLoaded: {
                // Views that want the keyboard get active focus as soon as they exist,
                // no click needed. (The surface side lives in Bar.qml / IslandState.keyboard.)
                if (Registry.wantsKeys(root.shown)) item.forceActiveFocus()
                root.syncEngaged()
            }
        }

        // ---- optional view contract (all members are optional) ----
        //   property bool engaged   : true while the user is actively working in the view
        //   signal closeRequested() : the view is done (e.g. an app was launched)
        Connections {
            target: loader.item
            ignoreUnknownSignals: true
            function onEngagedChanged()  { root.syncEngaged() }
            function onCloseRequested()  { IslandState.send(IslandState.Event.Close) }
        }
    }
}