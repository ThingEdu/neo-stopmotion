import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "singletons" as N
import "pages" as Pages

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    visible: true
    visibility: Window.Windowed
    title: "NeoStopMotion — Trạm 6"
    color: N.NeoConstants.background

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: splashComponent
    }

    Component {
        id: splashComponent
        Pages.SplashScreen {
            onFinished: stack.replace(capturePageComponent)
        }
    }

    Component {
        id: capturePageComponent
        Pages.CapturePage { }
    }
}
