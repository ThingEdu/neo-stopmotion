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
            text: "📷 Nút xanh / phím Space: chụp 1 ảnh"
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textPrimary
        }
        Text {
            text: "↩️ Phím Z: xoá ảnh cuối"
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textPrimary
        }
        Text {
            text: "🎬 Nút đỏ / phím Enter: tạo phim"
            font.pixelSize: N.NeoConstants.fontCaption
            color: N.NeoConstants.textPrimary
        }
    }
}
