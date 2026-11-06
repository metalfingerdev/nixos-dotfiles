import QtQuick
import qs.modules.components

// Tabs opens up between this and the status group, so it has to match Expanded's clock exactly.
Column {
    required property date date

    spacing: -1

    Label {
        text: Qt.formatDateTime(parent.date, "HH:mm")
        font.pixelSize: Config.title + 2
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }
    Label {
        text: Qt.formatDateTime(parent.date, "ddd d MMM")
        color: Config.dim
        font.pixelSize: Config.small
    }
}
