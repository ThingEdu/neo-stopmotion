import QtQuick
import QtQuick.Controls
import "../singletons" as N

Item {
    id: root
    signal finished()

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background

        Column {
            anchors.centerIn: parent
            spacing: N.NeoConstants.spacingL

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "🎬"
                font.pixelSize: 120
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Trạm Làm Phim Hoạt Hình"
                font.pixelSize: N.NeoConstants.fontTitle
                font.bold: true
                color: N.NeoConstants.primary
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Làng Maker @ FPT Shop"
                font.pixelSize: N.NeoConstants.fontBody
                color: N.NeoConstants.textSecondary
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: root.finished()
    }
}
