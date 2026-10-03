import QtQuick 2.5
QtObject {
    property bool highContrast:false
    property color accent: "#8fcdaa"
    readonly property color focusColor: highContrast ? "#ffffff":accent
    readonly property color panel: highContrast ? "#ff030605":"#f2080e0b"
    readonly property color backdrop: "#c8080d0b"
    readonly property color surface: "#080e0b"
    readonly property color text: highContrast ? "#f4f7f5":"#a7b5ad"
    readonly property color muted: highContrast ? "#c3cec7":"#77857e"
    readonly property color line: highContrast ? "#7e9587":"#35453c"
    readonly property color selectedFill: highContrast ? "#26352e":Qt.rgba(accent.r,accent.g,accent.b,0.1)
    readonly property color hoverFill: highContrast ? "#304138":Qt.rgba(accent.r,accent.g,accent.b,0.16)
}
