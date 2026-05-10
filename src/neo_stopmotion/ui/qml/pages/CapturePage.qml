import QtQuick
import QtQuick.Controls
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

        // Header with logo
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: N.NeoConstants.spacingM

            Image {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                source: resourcesUrl + "/images/maker_viet_logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                text: "TRẠM LÀM PHIM HOẠT HÌNH"
                font.pixelSize: N.NeoConstants.fontTitle
                font.bold: true
                color: N.NeoConstants.primary
            }

            Text {
                text: "•  NEO One — ThingEdu"
                font.pixelSize: N.NeoConstants.fontCaption
                color: N.NeoConstants.textSecondary
            }
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
            Layout.preferredHeight: 50
        }

        // Action buttons (mirror keyboard fallback Space/Z/Enter)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            spacing: N.NeoConstants.spacingL

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                text: "📷  CHỤP  (Space)"
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                onClicked: appController.handle_uart_command("SHOOT")
            }

            Button {
                Layout.preferredWidth: 220
                Layout.preferredHeight: 80
                text: "↩️  XOÁ FRAME  (Z)"
                font.pixelSize: N.NeoConstants.fontCaption
                onClicked: appController.handle_uart_command("UNDO")
            }

            Button {
                Layout.preferredWidth: 320
                Layout.preferredHeight: 80
                text: "🎬  TẠO PHIM  (Enter)"
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                highlighted: true
                enabled: N.AppState.frameCount >= 5
                onClicked: appController.handle_uart_command("EXPORT")

                ToolTip.visible: hovered && !enabled
                ToolTip.text: "Cần ít nhất 5 frame để tạo phim"
            }
        }
    }

    function flashCapture() { preview.flash() }
}
