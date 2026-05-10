import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons" as N

Item {
    id: root
    signal finished()

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background

        ColumnLayout {
            anchors.centerIn: parent
            spacing: N.NeoConstants.spacingL

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 220
                Layout.preferredHeight: 220
                source: resourcesUrl + "/images/maker_viet_logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Trạm Làm Phim Hoạt Hình"
                font.pixelSize: N.NeoConstants.fontTitle
                font.bold: true
                color: N.NeoConstants.primary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "NEO One — ThingEdu"
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
