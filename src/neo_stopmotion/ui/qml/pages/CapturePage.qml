// CapturePage.qml — Capture + FilmStrip review + delete frame (T-004)
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons" as N
import "../components"

Item {
    id: root

    Component.onCompleted: {
        N.AppState.webcamReady = true
        filmStrip.refresh()
    }

    // ---------------------------------------------------------------------------
    // Background
    // ---------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    // ---------------------------------------------------------------------------
    // Main layout
    // ---------------------------------------------------------------------------

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: N.NeoConstants.spacingL
        spacing: N.NeoConstants.spacingM

        // Header — 2 lines, balanced (matches Splash style)
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: N.NeoConstants.spacingS

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: N.NeoConstants.spacingM

                Image {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    source: resourcesUrl + "/images/maker_viet_logo.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    text: "TRẠM LÀM PHIM HOẠT HÌNH"
                    font.pixelSize: Math.round(N.NeoConstants.fontTitle * 1.25)
                    font.bold: true
                    color: N.NeoConstants.primary
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "NEO One — ThingEdu"
                font.pixelSize: N.NeoConstants.fontBody
                color: N.NeoConstants.textSecondary
            }
        }

        // Preview + Counter row
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: N.NeoConstants.spacingL

            LivePreview {
                id: preview
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 200
            }

            FrameCounter {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                Layout.maximumHeight: 320
            }
        }

        // ---------------------------------------------------------------------------
        // FilmStrip — dải thumbnail (T-004, design-spec §A)
        // ---------------------------------------------------------------------------

        FilmStrip {
            id: filmStrip
            Layout.fillWidth: true
            Layout.preferredHeight: 120

            onDeleteRequested: function(frameIndex) {
                deleteDialog.targetIndex = frameIndex
                deleteDialog.open()
            }
        }

        // ---------------------------------------------------------------------------
        // HintBar — dynamic hints based on filmstrip state (design-spec §E)
        // ---------------------------------------------------------------------------

        Rectangle {
            id: hintBarRect
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: N.NeoConstants.spacingM
                spacing: N.NeoConstants.spacingL

                Text {
                    id: hintText
                    text: {
                        if (filmStrip.selectedIndex > 0) {
                            return "Tấm số " + filmStrip.selectedIndex
                                + " đang chọn — nhấn XOÁ TẤM NÀY để xoá"
                        }
                        if (N.AppState.frameCount === 0) {
                            return "Bấm tấm ảnh trong filmstrip bên dưới để xem lại"
                        }
                        return "📷 Nút xanh / phím Space: chụp 1 ảnh  "
                            + "↩️ Phím Z: xoá ảnh cuối  "
                            + "🎬 Nút đỏ / phím Enter: tạo phim"
                    }
                    font.pixelSize: N.NeoConstants.fontCaption
                    color: filmStrip.selectedIndex > 0
                        ? N.NeoConstants.primary
                        : N.NeoConstants.textPrimary
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ---------------------------------------------------------------------------
        // Action buttons (Space/Z/Enter — mirror keyboard fallback)
        // ---------------------------------------------------------------------------

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            spacing: N.NeoConstants.spacingL

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                text: "📷  CHỤP  (Space)"
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                onClicked: appController.handle_uart_command("SHOOT")
            }

            Button {
                Layout.preferredWidth: 220
                Layout.preferredHeight: 80
                text: "↩️  XOÁ FRAME  (Z)"
                font.pixelSize: N.NeoConstants.fontCaption
                onClicked: appController.handle_uart_command("UNDO")
            }

            Button {
                Layout.preferredWidth: 320
                Layout.preferredHeight: 80
                text: "🎬  TẠO PHIM  (Enter)"
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                highlighted: true
                enabled: N.AppState.frameCount >= 5
                onClicked: appController.handle_uart_command("EXPORT")

                ToolTip.visible: hovered && !enabled
                ToolTip.text: "Cần ít nhất 5 frame để tạo phim"
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Keyboard shortcuts for filmstrip (Delete/Escape)
    // The parent StackView already handles Space/Z/Enter — we handle Delete here.
    // ---------------------------------------------------------------------------

    Keys.onDeletePressed: function(event) {
        if (filmStrip.selectedIndex > 0) {
            deleteDialog.targetIndex = filmStrip.selectedIndex
            deleteDialog.open()
            event.accepted = true
        }
    }
    Keys.onEscapePressed: function(event) {
        if (deleteDialog.visible) {
            deleteDialog.close()
        } else {
            filmStrip.selectedIndex = 0
        }
        event.accepted = true
    }

    // ---------------------------------------------------------------------------
    // Connections — refresh filmstrip on events
    // ---------------------------------------------------------------------------

    Connections {
        target: appController
        function onFrameCountChanged(n) {
            // Refresh filmstrip after shoot (append) or undo (LIFO)
            filmStrip.refresh()
            // Deselect after UNDO (frame count dropped)
            if (filmStrip.selectedIndex > n) {
                filmStrip.selectedIndex = 0
            }
        }
    }

    Connections {
        target: signalBusBridge
        function onFrameDeleted(newCount) {
            // Refresh filmstrip after arbitrary delete
            filmStrip.selectedIndex = 0
            filmStrip.refresh()
        }
        function onFrameUndone(newCount) {
            filmStrip.selectedIndex = 0
            filmStrip.refresh()
        }
    }

    // ---------------------------------------------------------------------------
    // Delete confirmation dialog (design-spec §D)
    // ---------------------------------------------------------------------------

    Popup {
        id: deleteDialog

        property int targetIndex: 0

        anchors.centerIn: Overlay.overlay
        width: 380
        height: 200
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: N.NeoConstants.surface
            radius: 20
            border.color: N.NeoConstants.error
            border.width: 3
        }

        // Dim background overlay
        Overlay.modal: Rectangle {
            color: "#99000000"
        }

        contentItem: Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: N.NeoConstants.spacingL

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Xoá tấm số " + deleteDialog.targetIndex + " nhé?"
                    font.pixelSize: N.NeoConstants.fontBody
                    font.bold: true
                    color: N.NeoConstants.textPrimary
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: N.NeoConstants.spacingM

                    // "THÔI ĐÃ" — default focus (safe choice)
                    Button {
                        id: cancelBtn
                        width: 140
                        height: 56
                        text: "THÔI ĐÃ"
                        font.pixelSize: N.NeoConstants.fontCaption
                        font.bold: true

                        background: Rectangle {
                            radius: 12
                            color: cancelBtn.hovered ? "#CCCCCC" : "#E0E0E0"
                        }
                        contentItem: Text {
                            text: cancelBtn.text
                            font: cancelBtn.font
                            color: N.NeoConstants.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: deleteDialog.close()

                        KeyNavigation.right: confirmBtn
                    }

                    // "XOÁ ĐI!" — destructive action
                    Button {
                        id: confirmBtn
                        width: 140
                        height: 56
                        text: "XOÁ ĐI!"
                        font.pixelSize: N.NeoConstants.fontCaption
                        font.bold: true

                        background: Rectangle {
                            radius: 12
                            color: confirmBtn.hovered ? "#B71C1C" : N.NeoConstants.error
                        }
                        contentItem: Text {
                            text: confirmBtn.text
                            font: confirmBtn.font
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            appController.handle_delete_frame(deleteDialog.targetIndex)
                            deleteDialog.close()
                        }

                        KeyNavigation.left: cancelBtn
                    }
                }
            }
        }

        // Focus "THÔI ĐÃ" when dialog opens (design-spec §D: default focus = hủy)
        onOpened: {
            cancelBtn.forceActiveFocus()
        }
    }

    // ---------------------------------------------------------------------------
    // Flash helper (called from MainWindow after SHOOT)
    // ---------------------------------------------------------------------------

    function flashCapture() { preview.flash() }
}
