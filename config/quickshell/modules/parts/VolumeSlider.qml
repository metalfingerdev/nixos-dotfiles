import QtQuick
import qs.modules.components
import qs.modules.services

Slider {
    property var node: Audio.sink
    readonly property int level: Audio.level(node)
    readonly property bool silent: Audio.isMuted(node)

    icon: Audio.levelIcon(level, silent)
    value: silent ? 0 : level / 100
    valueText: silent ? "Muted" : level + "%"
    iconClickable: true
    onMoved: v => Audio.setLevel(node, v * 100)
    onIconClicked: Audio.toggleMuted(node)
}
