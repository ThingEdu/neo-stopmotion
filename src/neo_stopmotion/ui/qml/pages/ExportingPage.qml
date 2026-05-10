import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons" as N

Item {
    id: root
    property real progress: 0.0
    property string statusText: "Đang ghép phim..."

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: N.NeoConstants.spacingXL
        width: parent.width * 0.6

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "🎬"
            font.pixelSize: 96
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.statusText
            font.pixelSize: N.NeoConstants.fontTitle
            color: N.NeoConstants.primary
        }

        ProgressBar {
            Layout.fillWidth: true
            from: 0.0
            to: 1.0
            value: root.progress
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(root.progress * 100) + "%"
            font.pixelSize: N.NeoConstants.fontBody
            color: N.NeoConstants.textSecondary
        }
    }
}
