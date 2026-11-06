import QtQuick
import qs.modules.components
import qs.modules.services

Slider {
    icon: Backlight.icon
    value: Backlight.percent / 100
    onMoved: v => Backlight.set(v * 100)
}
