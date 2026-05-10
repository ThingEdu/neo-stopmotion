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
                    text: "MP4 lưu tại: " + root.mp4Path
                    font.pixelSize: 12
                    color: N.NeoConstants.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: N.NeoConstants.buttonHeight + 8
            Layout.preferredWidth: 360
            text: "🔁  Quay lại làm phim mới"
            font.pixelSize: N.NeoConstants.fontButton
            font.bold: true
            highlighted: true
            onClicked: appController.reset_session()
        }
    }
}
