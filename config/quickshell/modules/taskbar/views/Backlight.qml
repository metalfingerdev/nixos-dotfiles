import QtQuick
import qs.modules.taskbar
import qs.modules.services

Meter {
    label:     "bri"
    fraction:  Brightness.percent / 100
    valueText: String(Brightness.percent)
}