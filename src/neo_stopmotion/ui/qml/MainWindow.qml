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
            onFinished: {
                stack.replace(capturePlaceholder)
            }
        }
    }

    Component {
        id: capturePlaceholder
        Item {
            Rectangle {
                anchors.fill: parent
                color: N.NeoConstants.background
                Text {
                    anchors.centerIn: parent
                    text: "CapturePage (placeholder)"
                    font.pixelSize: N.NeoConstants.fontTitle
                    color: N.NeoConstants.primary
                }
            }
        }
    }
}
