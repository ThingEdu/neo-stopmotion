import QtQuick
import QtQuick.Controls
import QtQuick.Window

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    visible: true
    title: "NeoStopMotion — Trạm 6"

    Rectangle {
        anchors.fill: parent
        color: "#FFF8E1"

        Text {
            anchors.centerIn: parent
            text: "Chào Trạm 6 — Làm Phim Hoạt Hình"
            font.pixelSize: 36
            color: "#FF7043"
        }
    }
}
