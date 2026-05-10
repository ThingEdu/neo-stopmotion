import QtQuick
import QtQuick.Layouts
import "../singletons" as N

Rectangle {
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.margins: N.NeoConstants.spacingM
        spacing: N.NeoConstants.spacingL

        Text {
            text: "🔴 Bấm: chụp 1 frame"
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textPrimary
        }
        Text {
            text: "⏱️ Giữ 1s: xóa frame cuối"
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textPrimary
        }
        Text {
            text: "🎬 Giữ 3s: tạo phim"
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textPrimary
        }
    }
}
