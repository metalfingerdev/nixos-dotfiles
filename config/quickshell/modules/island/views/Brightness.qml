import QtQuick
import qs.modules.components
import qs.modules.services

// The brightness toast: a pill slider you can also drag.
Item {
    implicitWidth: 340
    implicitHeight: 60

    Slider {
        anchors { fill: parent; margins: 8 }
        icon: Backlight.percent < 34 ? "brightness_low" : Backlight.percent < 67 ? "brightness_medium" : "brightness_high"
        value: Backlight.percent / 100
        activeFocusOnTab: false
        onMoved: v => Backlight.set(v * 100)
    }
}
