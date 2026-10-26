import QtQuick
import qs.modules.components
import qs.modules.services

// The volume toast: a pill slider you can also drag; the icon mutes.
Item {
    implicitWidth: 440
    implicitHeight: 72

    Slider {
        anchors { fill: parent; margins: 10 }
        icon: Audio.muted ? "volume_off" : Audio.volume < 34 ? "volume_mute" : Audio.volume < 67 ? "volume_down" : "volume_up"
        value: Audio.muted ? 0 : Audio.volume / 100
        valueText: Audio.muted ? "Muted" : Audio.volume + "%"
        iconClickable: true
        activeFocusOnTab: false
        onMoved: v => Audio.setVolume(v * 100)
        onIconClicked: Audio.toggleMute()
    }
}
