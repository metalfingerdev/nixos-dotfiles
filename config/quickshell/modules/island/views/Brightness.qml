import QtQuick
import qs.modules.components
import qs.modules.services

Meter {
    label:     "bri"
    fraction:  Backlight.percent / 100
    valueText: String(Backlight.percent)
}