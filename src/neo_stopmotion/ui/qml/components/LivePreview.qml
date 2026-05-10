import QtQuick
import "../singletons" as N

Item {
    id: root

    Image {
        id: preview
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        cache: false
        source: "image://preview/" + N.AppState.previewCounter
    }

    Timer {
        interval: 33  // ~30fps
        repeat: true
        running: N.AppState.webcamReady
        onTriggered: N.AppState.previewCounter++
    }

    Rectangle {
        id: flashOverlay
        anchors.fill: parent
        color: "white"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    function flash() {
        flashOverlay.opacity = 0.8
        flashTimer.restart()
    }

    Timer {
        id: flashTimer
        interval: 100
        onTriggered: flashOverlay.opacity = 0
    }
}
