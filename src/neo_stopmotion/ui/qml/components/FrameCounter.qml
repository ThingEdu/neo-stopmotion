import QtQuick
import QtQuick.Layouts
import "../singletons" as N

Rectangle {
    radius: 16
    color: N.NeoConstants.surface
    border.color: N.NeoConstants.primary
    border.width: 2

    ColumnLayout {
        anchors.centerIn: parent
        spacing: N.NeoConstants.spacingS

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "FRAME"
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textSecondary
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: N.AppState.frameCount
            font.pixelSize: N.NeoConstants.fontFrameCount
            font.bold: true
            color: N.NeoConstants.primary
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Thời lượng: " + N.AppState.durationDisplay
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textPrimary
        }
    }
}
