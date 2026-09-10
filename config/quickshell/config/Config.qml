import QtQuick
pragma Singleton

QtObject {
    // Core Palette
    readonly property color bgDark: "#141216"
    readonly property color highlight: "#27232b"
    readonly property color bgLight: "#27232b"
    readonly property color foreground: "#d8cab8"
    readonly property color background: '#c0141216'
    readonly property color muted: '#80d8cab8'
    // Accents
    readonly property color accent: "#ac82e9"
    readonly property color accentDeep: "#8f56e1"
    readonly property color warning: "#fcb167"
    readonly property color danger: "#fc4649"
    // Typography
    readonly property string font: "Maple Mono"
    readonly property string fontMono: "Maple Mono NF"
    readonly property int fontSize: 14
    readonly property int radius: 8
    readonly property int margin: 8
    readonly property int spacing: 8
    // Bar
    readonly property int bottom: 12
    readonly property int sides: 400
    readonly property int top: 64

}