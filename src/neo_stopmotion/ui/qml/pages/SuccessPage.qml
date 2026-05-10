import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../singletons" as N

Item {
    id: root
    property string mp4Path: ""
    property string gifPath: ""
    property string shareUrl: ""
    property string qrPath: ""

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: N.NeoConstants.spacingL
        spacing: N.NeoConstants.spacingM

        // Branded header
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: N.NeoConstants.spacingM

            Image {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                source: resourcesUrl + "/images/maker_viet_logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Maker Việt × ThingEdu"
                    font.pixelSize: N.NeoConstants.fontBody
                    font.bold: true
                    color: N.NeoConstants.primary
                }
                Text {
                    text: "NEO One — Trạm Làm Phim"
                    font.pixelSize: N.NeoConstants.fontCaption
                    color: N.NeoConstants.textSecondary
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "🎉 Phim của con đã xong!"
            font.pixelSize: N.NeoConstants.fontTitle
            font.bold: true
            color: N.NeoConstants.success
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: N.NeoConstants.spacingL

            // Left: video preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "black"
                radius: 12
                border.color: N.NeoConstants.primary
                border.width: 3

                MediaPlayer {
                    id: player
                    source: root.mp4Path !== "" ? "file://" + root.mp4Path : ""
                    videoOutput: vo
                    audioOutput: AudioOutput { volume: 0 }
                    loops: MediaPlayer.Infinite
                    onSourceChanged: if (root.mp4Path !== "") play()
                    Component.onCompleted: if (root.mp4Path !== "") play()
                }
                VideoOutput {
                    id: vo
                    anchors.fill: parent
                    anchors.margins: 8
                }
            }

            // Right: QR + share URL
            ColumnLayout {
                Layout.preferredWidth: 420
                Layout.fillHeight: true
                spacing: N.NeoConstants.spacingM

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.qrPath !== "" ? "📱 Phụ huynh quét mã" : "💾 Phim đã lưu trên máy"
                    font.pixelSize: N.NeoConstants.fontBody
                    font.bold: true
                    color: N.NeoConstants.textPrimary
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 360
                    Layout.preferredHeight: 360
                    color: "white"
                    border.color: N.NeoConstants.primary
                    border.width: 2
                    radius: 8
                    visible: root.qrPath !== ""

                    Image {
                        anchors.fill: parent
                        anchors.margins: 8
                        source: root.qrPath !== "" ? "file://" + root.qrPath : ""
                        fillMode: Image.PreserveAspectFit
                        cache: false
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 400
                    text: root.shareUrl !== "" ? root.shareUrl : ""
                    font.pixelSize: N.NeoConstants.fontCaption
                    color: N.NeoConstants.secondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAnywhere
                    visible: root.shareUrl !== ""
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 400
                    text: "Phim lưu tại: " + root.mp4Path
                    font.pixelSize: 12
                    color: N.NeoConstants.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // Footer hint + reset button
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: N.NeoConstants.spacingL

            Text {
                text: "💡 Bấm Space (hoặc IO1 ThingBot) để làm phim mới ngay"
                font.pixelSize: N.NeoConstants.fontCaption
                color: N.NeoConstants.warning
            }

            Button {
                Layout.preferredHeight: N.NeoConstants.buttonHeight
                Layout.preferredWidth: 280
                text: "🔁  Làm phim mới"
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                highlighted: true
                onClicked: appController.reset_session()
            }
        }
    }
}
