pragma Singleton
import QtQuick

QtObject {
    // Brand colors (animation theme)
    readonly property color primary:    "#FF7043"
    readonly property color secondary:  "#1565C0"
    readonly property color accent:     "#FFD600"
    readonly property color background: "#FFF8E1"
    readonly property color surface:    "#FFFFFF"
    readonly property color textPrimary: "#212121"
    readonly property color textSecondary: "#616161"
    readonly property color success:    "#2E7D32"
    readonly property color warning:    "#FF8F00"
    readonly property color error:      "#C62828"

    // Typography
    property bool largeTextMode: false
    readonly property real textScale:    largeTextMode ? 1.25 : 1.0
    readonly property int fontTitle:     Math.round(36 * textScale)
    readonly property int fontBody:      Math.round(24 * textScale)
    readonly property int fontButton:    Math.round(24 * textScale)
    readonly property int fontCaption:   Math.round(18 * textScale)
    readonly property int fontFrameCount: Math.round(72 * textScale)

    // Touch targets
    readonly property int touchMin:      largeTextMode ? 60 : 52
    readonly property int buttonHeight:  largeTextMode ? 68 : 60
    readonly property int previewWidth:  1280
    readonly property int previewHeight: 720

    // Animation
    readonly property int animFast:    200
    readonly property int animNormal:  400
    readonly property int animSlow:    800

    // Stop-motion specific
    readonly property real onionOpacity: 0.30
    readonly property int targetFps:     10
    readonly property int minFrames:     5
    readonly property int maxFrames:     100

    // Spacing
    readonly property int spacingS: 8
    readonly property int spacingM: 16
    readonly property int spacingL: 24
    readonly property int spacingXL: 40
}
