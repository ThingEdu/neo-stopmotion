// CapturePage.qml — Capture + FilmStrip review + delete frame (T-004)
//                   Camera picker button (T-005)
//                   Speed selector bar (T-006)
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
                Layout.minimumHeight: 180
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
        // HintBar — dynamic hints + "Đổi camera" button (T-005, design-spec §E)
        // ---------------------------------------------------------------------------

        Rectangle {
            id: hintBarRect
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: N.NeoConstants.spacingS
                spacing: N.NeoConstants.spacingM

                Text {
                    id: hintText
                    Layout.fillWidth: true
                    text: {
                        if (filmStrip.selectedIndex > 0) {
                            return "Tấm số " + filmStrip.selectedIndex
                                + " đang chọn — nhấn XOÁ TẤM NÀY để xoá"
                        }
                        if (N.AppState.frameCount === 0) {
                            return "Bấm tấm ảnh trong filmstrip bên dưới để xem lại"
                        }
                        return "📷 Space: chụp  ↩️ Z: xoá cuối  🎬 Enter: tạo phim"
                    }
                    font.pixelSize: N.NeoConstants.fontCaption
                    color: filmStrip.selectedIndex > 0
                        ? N.NeoConstants.primary
                        : N.NeoConstants.textPrimary
                    wrapMode: Text.WordWrap
                }

                // T-005: "Đổi camera" button — discrete, for Tho Ca
                Button {
                    id: changeCameraBtn
                    width: 160
                    height: 40
                    text: "📷 Đổi camera"
                    font.pixelSize: N.NeoConstants.fontCaption
                    visible: true  // always visible on CapturePage

                    background: Rectangle {
                        radius: 8
                        color: changeCameraBtn.hovered
                            ? N.NeoConstants.surface
                            : "transparent"
                        border.color: changeCameraBtn.hovered
                            ? "#424242"
                            : N.NeoConstants.textSecondary
                        border.width: 1
                    }
                    contentItem: Text {
                        text: changeCameraBtn.text
                        font: changeCameraBtn.font
                        color: N.NeoConstants.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Larger touch area
                    topPadding: 6
                    bottomPadding: 6

                    onClicked: cameraPicker.openPicker(appController.get_current_webcam_index())

                    ToolTip.visible: hovered
                    ToolTip.text: "Thợ Cả: đổi camera đang dùng"
                }
            }
        }

        // ---------------------------------------------------------------------------
        // T-006: SpeedSelectorBar — between HintBar and Action Buttons
        // ---------------------------------------------------------------------------

        Rectangle {
            id: speedSelectorBar
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            color: N.NeoConstants.surface
            radius: 12
            border.color: "#E0E0E0"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: N.NeoConstants.spacingS

                // Label
                Text {
                    text: "Tốc độ phim:"
                    font.pixelSize: N.NeoConstants.fontCaption
                    color: N.NeoConstants.textSecondary
                }

                // 3 speed buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        id: speedBtns
                        model: [
                            { label: "Cham",  fps: 5,  icon: "🐌" },
                            { label: "Vua",   fps: 8,  icon: "🐇" },
                            { label: "Nhanh", fps: 12, icon: "⚡" }
                        ]

                        delegate: Item {
                            id: speedBtnItem
                            Layout.fillWidth: true
                            height: 72

                            // Track state
                            property bool isActive: appController.get_selected_speed_label() === modelData.label
                            property bool isSuggested: {
                                if (isActive) return false
                                var sg = appController.get_suggested_speed(N.AppState.frameCount)
                                return sg === modelData.label
                            }
                            property bool isDisabled: N.AppState.frameCount === 0

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                opacity: speedBtnItem.isDisabled ? 0.45 : 1.0
                                color: {
                                    if (speedBtnItem.isActive) return "#FFF3E0"
                                    if (speedBtnItem.isSuggested) return "#FFFDE7"
                                    if (speedBtnItem.isDisabled) return "#F5F5F5"
                                    return N.NeoConstants.surface
                                }
                                border.color: {
                                    if (speedBtnItem.isActive) return N.NeoConstants.primary
                                    if (speedBtnItem.isSuggested) return N.NeoConstants.accent
                                    return "#E0E0E0"
                                }
                                border.width: speedBtnItem.isActive ? 3 : (speedBtnItem.isSuggested ? 2 : 1)

                                // Suggested border pulse animation
                                SequentialAnimation on border.width {
                                    running: speedBtnItem.isSuggested
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 2; duration: 750 }
                                    NumberAnimation { to: 1; duration: 750 }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        // Use text fallbacks to avoid emoji issues on Linux ARM
                                        text: modelData.label === "Cham" ? "Chậm"
                                            : modelData.label === "Vua" ? "Vừa" : "Nhanh"
                                        font.pixelSize: N.NeoConstants.fontBody
                                        font.bold: speedBtnItem.isActive
                                        color: speedBtnItem.isActive
                                            ? N.NeoConstants.primary
                                            : N.NeoConstants.textPrimary
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.fps + " fps"
                                        font.pixelSize: N.NeoConstants.fontCaption
                                        color: N.NeoConstants.textSecondary
                                    }
                                    // Gợi ý badge
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: speedBtnItem.isSuggested
                                        width: suggestText.width + 8
                                        height: 20
                                        color: N.NeoConstants.accent
                                        radius: 4
                                        Text {
                                            id: suggestText
                                            anchors.centerIn: parent
                                            text: "★ Gợi ý"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: N.NeoConstants.textPrimary
                                        }
                                    }
                                }

                                // Scale bounce on select
                                scale: 1.0
                                Behavior on scale {
                                    SequentialAnimation {
                                        NumberAnimation { to: 0.95; duration: 75 }
                                        NumberAnimation { to: 1.0; duration: 75 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !speedBtnItem.isDisabled
                                    hoverEnabled: true
                                    onClicked: {
                                        appController.select_speed(modelData.label)
                                        speedFeedbackToast.show(modelData.label, modelData.fps)
                                        // Trigger re-evaluation of isActive across all buttons
                                        speedBtns.model = speedBtns.model
                                    }
                                }
                            }
                        }
                    }
                }

                // Hint text (shown when suggestion differs from selection)
                Text {
                    id: speedHintText
                    Layout.fillWidth: true
                    visible: {
                        if (N.AppState.frameCount === 0) return false
                        var sg = appController.get_suggested_speed(N.AppState.frameCount)
                        var sel = appController.get_selected_speed_label()
                        return sg !== "" && sg !== sel
                    }
                    text: {
                        var sg = appController.get_suggested_speed(N.AppState.frameCount)
                        if (sg === "Cham") return "💡 Phim ít tấm nên chọn Chậm để xem rõ nha!"
                        if (sg === "Nhanh") return "💡 Nhiều tấm rồi, chọn Nhanh cho phim mượt nha!"
                        return ""
                    }
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.italic: true
                    color: N.NeoConstants.warning
                    opacity: 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    onVisibleChanged: opacity = visible ? 1 : 0
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
    // T-005: Camera picker popup
    // ---------------------------------------------------------------------------
    CameraPickerPopup {
        id: cameraPicker
        onCameraConfirmed: function(index) {
            // Live preview automatically updates via webcam_ready signal
        }
        onCancelled: {
            // Nothing extra — camera unchanged
        }
    }

    // ---------------------------------------------------------------------------
    // T-006: Speed feedback toast (bottom-right, 1.5s)
    // ---------------------------------------------------------------------------
    Rectangle {
        id: speedFeedbackToast
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: N.NeoConstants.spacingL
        width: toastText.implicitWidth + 24
        height: 44
        radius: 8
        color: "#DD212121"
        opacity: 0
        visible: opacity > 0

        property string message: ""

        function show(label, fps) {
            var labelVN = label === "Cham" ? "Chậm" : label === "Vua" ? "Vừa" : "Nhanh"
            message = "Đã chọn: " + labelVN + " (" + fps + "fps)"
            opacity = 1
            hideTimer.restart()
        }

        Text {
            id: toastText
            anchors.centerIn: parent
            anchors.margins: 12
            text: speedFeedbackToast.message
            font.pixelSize: N.NeoConstants.fontCaption
            color: "#FFFFFF"
        }

        Timer {
            id: hideTimer
            interval: 1500
            onTriggered: speedFeedbackToast.opacity = 0
        }

        Behavior on opacity { NumberAnimation { duration: 300 } }
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
        function onWebcamReady() {
            // T-005: camera changed — restart live preview counter
            N.AppState.previewCounter++
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
