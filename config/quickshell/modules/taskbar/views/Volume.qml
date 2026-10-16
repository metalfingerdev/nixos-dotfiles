import QtQuick
import qs.modules.taskbar
import qs.modules.services

Meter {
    label:     Audio.muted ? "mute" : "vol"
    fraction:  Audio.muted ? 0 : Audio.volume / 100
    valueText: Audio.muted ? "-" : String(Audio.volume)
}