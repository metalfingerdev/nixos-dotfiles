import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source
    property real radius: 0

    visible: String(source).length > 0

    Image {
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        layer.enabled: root.visible
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true

        Rectangle {
            anchors.fill: parent
            radius: root.radius
        }
    }
}