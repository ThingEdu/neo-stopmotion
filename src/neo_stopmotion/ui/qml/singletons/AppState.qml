pragma Singleton
import QtQuick

QtObject {
    property int frameCount: 0
    property string sessionId: ""
    property string status: "idle"  // idle | capturing | exporting | completed | error
    property int previewCounter: 0
    property bool uartConnected: false
    property bool webcamReady: false
    property string currentTitle: ""
    property string warningBanner: ""
    property string errorBanner: ""

    // Computed
    readonly property real durationSeconds: frameCount / 10.0
    readonly property string durationDisplay: durationSeconds.toFixed(1) + "s"
}
