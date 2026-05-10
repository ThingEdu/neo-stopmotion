import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../singletons" as N

Item {
    id: root
    property string mp4Path: ""
    property string gifPath: ""

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: N.NeoConstants.spacingL
        spacing: N.NeoConstants.spacingL

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "🎉 Phim của con đã xong!"
            font.pixelSize: N.NeoConstants.fontTitle
            font.bold: true
            color: N.NeoConstants.success
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: 1280
            Layout.alignment: Qt.AlignHCenter
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

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "MP4: " + root.mp4Path
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textSecondary
            wrapMode: Text.WrapAnywhere
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: N.NeoConstants.spacingL

            Button {
                Layout.preferredHeight: N.NeoConstants.buttonHeight + 8
                Layout.preferredWidth: 280
                text: "🔁 Quay lại làm phim mới"
                font.pixelSize: N.NeoConstants.fontButton
                onClicked: appController.reset_session()
            }
        }
    }
}
