import QtQuick
import QtQuick.Layouts
import "../singletons" as N
import "../components"

Item {
    id: root

    Component.onCompleted: N.AppState.webcamReady = true

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: N.NeoConstants.spacingL
        spacing: N.NeoConstants.spacingM

        // Header
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "TRẠM LÀM PHIM HOẠT HÌNH"
            font.pixelSize: N.NeoConstants.fontTitle
            font.bold: true
            color: N.NeoConstants.primary
        }

        // Preview + Counter row
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: N.NeoConstants.spacingL

            LivePreview {
                id: preview
                Layout.fillWidth: true
                Layout.preferredHeight: 720
            }

            FrameCounter {
                Layout.preferredWidth: 240
                Layout.preferredHeight: 320
            }
        }

        HintBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
        }
    }

    function flashCapture() { preview.flash() }
}
