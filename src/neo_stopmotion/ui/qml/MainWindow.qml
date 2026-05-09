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
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Space) {
                appController.handle_uart_command("SHOOT")
                event.accepted = true
            } else if (event.key === Qt.Key_Z) {
                appController.handle_uart_command("UNDO")
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                appController.handle_uart_command("EXPORT")
                event.accepted = true
            }
        }
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

    Connections {
        target: appController
        function onFrameCountChanged(n) {
            N.AppState.frameCount = n
        }
    }
}
