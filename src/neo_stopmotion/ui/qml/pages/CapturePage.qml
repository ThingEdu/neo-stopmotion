// CapturePage.qml — Variant B "Cột phải" (T-010 + T-011)
// Layout: header | body(preview + rail) | filmstrip | legend
// Mockup: docs/03-codebase/design/brand/html-mockups/02-capture-B.html
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

    // Signal for T-012 (library navigation) — T-012 sẽ connect
    signal navigateToLibrary()

    // ---------------------------------------------------------------------------
    // Background
    // ---------------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    // ---------------------------------------------------------------------------
    // Root ColumnLayout: header | body | filmwrap | legend
    // ---------------------------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================================
        // HEADER — logo + tiêu đề | Phim đã làm (G) + Đổi camera (C) + Phím tắt (?)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: 58
            color: N.NeoConstants.surface
            // border bottom
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: "#FFE0B2"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: N.NeoConstants.spacingL
                anchors.rightMargin: N.NeoConstants.spacingL

                // Brand: icon + title
                RowLayout {
                    spacing: 12

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 10
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#FF7043" }
                            GradientStop { position: 1.0; color: "#FF8F00" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "🎬"
                            font.pixelSize: 18
                        }
                    }

                    Text {
                        text: "Xưởng phim của bé"
                        font.pixelSize: 20
                        font.bold: true
                        color: N.NeoConstants.textPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                // Header buttons (right side)
                RowLayout {
                    spacing: 10

                    // "Phim đã làm" — G — hook for T-012
                    Button {
                        id: libraryBtn
                        height: 42
                        text: "📁 Phim đã làm"
                        font.pixelSize: N.NeoConstants.fontCaption
                        font.bold: true

                        background: Rectangle {
                            radius: 12
                            color: libraryBtn.hovered
                                ? Qt.lighter(N.NeoConstants.secondary, 1.7)
                                : N.NeoConstants.surface
                            border.color: N.NeoConstants.secondary
                            border.width: 2
                        }
                        contentItem: RowLayout {
                            spacing: 6
                            Text {
                                text: libraryBtn.text
                                font: libraryBtn.font
                                color: N.NeoConstants.secondary
                            }
                            Rectangle {
                                width: kbdG.implicitWidth + 10
                                height: 20
                                radius: 5
                                color: "#FFFFFF"
                                border.color: "#D8C9A8"
                                border.width: 1
                                Text {
                                    id: kbdG
                                    anchors.centerIn: parent
                                    text: "G"
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: "monospace"
                                    color: "#7a6200"
                                }
                            }
                        }
                        leftPadding: 14
                        rightPadding: 14

                        onClicked: root.navigateToLibrary()
                    }

                    // "Đổi camera" — C
                    Button {
                        id: changeCameraBtn
                        height: 42
                        text: "📷 Đổi camera"
                        font.pixelSize: N.NeoConstants.fontCaption
                        font.bold: true

                        background: Rectangle {
                            radius: 12
                            color: changeCameraBtn.hovered
                                ? Qt.lighter(N.NeoConstants.secondary, 1.7)
                                : N.NeoConstants.surface
                            border.color: N.NeoConstants.secondary
                            border.width: 2
                        }
                        contentItem: RowLayout {
                            spacing: 6
                            Text {
                                text: changeCameraBtn.text
                                font: changeCameraBtn.font
                                color: N.NeoConstants.secondary
                            }
                            Rectangle {
                                width: kbdC.implicitWidth + 10
                                height: 20
                                radius: 5
                                color: "#FFFFFF"
                                border.color: "#D8C9A8"
                                border.width: 1
                                Text {
                                    id: kbdC
                                    anchors.centerIn: parent
                                    text: "C"
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: "monospace"
                                    color: "#7a6200"
                                }
                            }
                        }
                        leftPadding: 14
                        rightPadding: 14

                        onClicked: cameraPicker.openPicker(appController.get_current_webcam_index())
                    }

                    // "Phím tắt" — ?
                    Button {
                        id: helpBtn
                        height: 42
                        text: "⌨️ Phím tắt"
                        font.pixelSize: N.NeoConstants.fontCaption
                        font.bold: true

                        background: Rectangle {
                            radius: 12
                            color: helpBtn.hovered ? "#E8DFD0" : "#F2EAD8"
                            border.width: 0
                        }
                        contentItem: RowLayout {
                            spacing: 6
                            Text {
                                text: helpBtn.text
                                font: helpBtn.font
                                color: N.NeoConstants.textSecondary
                            }
                            Rectangle {
                                width: kbdQ.implicitWidth + 10
                                height: 20
                                radius: 5
                                color: "#FFFFFF"
                                border.color: "#D8C9A8"
                                border.width: 1
                                Text {
                                    id: kbdQ
                                    anchors.centerIn: parent
                                    text: "?"
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: "monospace"
                                    color: "#7a6200"
                                }
                            }
                        }
                        leftPadding: 12
                        rightPadding: 12

                        onClicked: shortcutsOverlay.open()
                    }
                }
            }
        }

        // ====================================================================
        // BODY — preview lớn (trái) | cột phải (rail)
        // ====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.topMargin: 16
            Layout.bottomMargin: 6

            // ------------------------------------------------------------------
            // Preview — chiếm phần lớn không gian
            // ------------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 360
                radius: 22
                color: "#2e3a44"
                border.color: "#FFFFFF"
                border.width: 4
                clip: true

                // Live camera preview
                LivePreview {
                    id: preview
                    anchors.fill: parent
                    anchors.margins: 4
                }

                // LIVE badge (top-right)
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 16
                    height: 30
                    width: liveBadgeRow.implicitWidth + 20
                    radius: 999
                    color: "#73000000"

                    RowLayout {
                        id: liveBadgeRow
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 11
                            height: 11
                            radius: 6
                            color: "#ff4d4d"
                            SequentialAnimation on opacity {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 550 }
                                NumberAnimation { to: 1.0; duration: 550 }
                            }
                        }
                        Text {
                            text: "ĐANG QUAY"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }
                }

                // Hint overlay (bottom-centre)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 14
                    height: 40
                    width: hintText.implicitWidth + 32
                    radius: 999
                    color: "#F0FFFFFF"
                    visible: N.AppState.frameCount === 0

                    Text {
                        id: hintText
                        anchors.centerIn: parent
                        text: "📸 Di chuyển nhân vật một chút rồi CHỤP nhé!"
                        font.pixelSize: 17
                        font.bold: true
                        color: N.NeoConstants.textPrimary
                    }
                }
            }

            // ------------------------------------------------------------------
            // Rail (cột phải) — 300px fixed
            // ------------------------------------------------------------------
            ColumnLayout {
                Layout.preferredWidth: 300
                Layout.minimumWidth: 300
                Layout.maximumWidth: 300
                Layout.fillHeight: true
                spacing: 12

                // --- Huy hiệu đếm frame (vàng) ---
                Rectangle {
                    Layout.fillWidth: true
                    height: frameCountBadgeCol.implicitHeight + 24
                    radius: 18
                    color: N.NeoConstants.accent
                    // Golden shadow
                    layer.enabled: true

                    ColumnLayout {
                        id: frameCountBadgeCol
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: N.AppState.frameCount
                            font.pixelSize: N.NeoConstants.fontFrameCount
                            font.bold: true
                            color: "#3a2e00"
                            lineHeight: 1.0
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "TẤM ẢNH"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#7a6200"
                            font.letterSpacing: 0.5
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "⏱ " + N.AppState.durationDisplay + " phim"
                            font.pixelSize: 15
                            font.bold: false
                            color: "#7a6200"
                        }
                    }
                }

                // --- Hộp chọn tốc độ ---
                Rectangle {
                    Layout.fillWidth: true
                    height: speedBoxContent.implicitHeight + 20
                    radius: 16
                    color: N.NeoConstants.surface

                    ColumnLayout {
                        id: speedBoxContent
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: N.NeoConstants.spacingS

                        // Label row with key hints
                        RowLayout {
                            spacing: 6
                            Text {
                                text: "Tốc độ phim"
                                font.pixelSize: 13
                                font.bold: true
                                color: N.NeoConstants.textSecondary
                            }
                            // key hints 1/2/3
                            Repeater {
                                model: ["1", "2", "3"]
                                delegate: Rectangle {
                                    width: kbdSpeedLabel.implicitWidth + 10
                                    height: 18
                                    radius: 4
                                    color: "#FFFFFF"
                                    border.color: "#D8C9A8"
                                    border.width: 1
                                    Text {
                                        id: kbdSpeedLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: "monospace"
                                        color: "#7a6200"
                                    }
                                }
                            }
                        }

                        // Segmented speed buttons
                        Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            radius: 13
                            color: "#FFF3D6"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 4

                                Repeater {
                                    id: speedBtns
                                    model: [
                                        { label: "Cham", fps: 5, icon: "🐌", key: "1" },
                                        { label: "Vua",  fps: 8, icon: "🐇", key: "2" },
                                        { label: "Nhanh",fps: 12,icon: "⚡", key: "3" }
                                    ]

                                    delegate: Item {
                                        id: speedSegItem
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        property bool isActive: N.AppState.selectedSpeedLabel === modelData.label

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 10
                                            color: speedSegItem.isActive
                                                ? N.NeoConstants.primary
                                                : "transparent"

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            // Key badge (top-right corner)
                                            Text {
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.topMargin: 2
                                                anchors.rightMargin: 5
                                                text: modelData.key
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: speedSegItem.isActive ? "#ffd9c9" : "#bbbbbb"
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 1

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.icon
                                                    font.pixelSize: 21
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.label === "Cham" ? "Chậm"
                                                        : modelData.label === "Vua" ? "Vừa" : "Nhanh"
                                                    font.pixelSize: 14
                                                    font.bold: speedSegItem.isActive
                                                    color: speedSegItem.isActive ? "#FFFFFF" : N.NeoConstants.textSecondary
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    appController.select_speed(modelData.label)
                                                    N.AppState.selectedSpeedLabel = modelData.label
                                                    speedFeedbackToast.show(modelData.label, modelData.fps)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Nút CHỤP (IO1/Space) ---
                Item {
                    Layout.fillWidth: true
                    height: 104

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            id: shootBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            font.pixelSize: 22
                            font.bold: true

                            background: Rectangle {
                                radius: 18
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#FF7043" }
                                    GradientStop { position: 1.0; color: "#FF5722" }
                                }
                            }
                            contentItem: Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "📷"
                                    font.pixelSize: 42
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "CHỤP"
                                    font.pixelSize: 22
                                    font.bold: true
                                    color: "#FFFFFF"
                                }
                            }

                            onClicked: appController.handle_uart_command("SHOOT")
                        }

                        // IO1 + Space tags
                        Column {
                            spacing: 5
                            width: 54

                            Rectangle {
                                width: parent.width
                                height: 22
                                radius: 5
                                color: "#FFFFFF"
                                border.color: "#D8C9A8"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Space"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "monospace"
                                    color: "#7a6200"
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 22
                                radius: 5
                                color: "#212121"
                                Text {
                                    anchors.centerIn: parent
                                    text: "IO1"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#FFFFFF"
                                    font.letterSpacing: 0.5
                                }
                            }
                        }
                    }
                }

                // --- Nút Xoá tấm (IO2/Del) ---
                Item {
                    Layout.fillWidth: true
                    height: 52

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            id: deleteBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: "↩️ Xoá tấm"
                            font.pixelSize: 16
                            font.bold: true

                            background: Rectangle {
                                radius: 14
                                color: N.NeoConstants.surface
                                border.color: N.NeoConstants.error
                                border.width: 2
                            }
                            contentItem: Text {
                                text: deleteBtn.text
                                font: deleteBtn.font
                                color: N.NeoConstants.error
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                var idx = filmStrip.selectedIndex
                                if (idx > 0) {
                                    deleteDialog.targetIndex = idx
                                    deleteDialog.open()
                                } else if (N.AppState.frameCount > 0) {
                                    deleteDialog.targetIndex = N.AppState.frameCount
                                    deleteDialog.open()
                                }
                            }
                        }

                        // IO2 + Del tags
                        Column {
                            spacing: 5
                            width: 54

                            Rectangle {
                                width: parent.width
                                height: 22
                                radius: 5
                                color: "#FFFFFF"
                                border.color: "#D8C9A8"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Del"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "monospace"
                                    color: "#7a6200"
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 22
                                radius: 5
                                color: "#212121"
                                Text {
                                    anchors.centerIn: parent
                                    text: "IO2"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#FFFFFF"
                                    font.letterSpacing: 0.5
                                }
                            }
                        }
                    }
                }

                // Spacer to push "Tạo phim" to bottom
                Item { Layout.fillHeight: true }

                // --- Nút TẠO PHIM (IO3/Enter) ---
                Item {
                    Layout.fillWidth: true
                    height: 70

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Button {
                            id: makeFilmBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: "🎬 TẠO PHIM"
                            font.pixelSize: 22
                            font.bold: true
                            enabled: N.AppState.frameCount >= N.NeoConstants.minFrames

                            background: Rectangle {
                                radius: 18
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: makeFilmBtn.enabled ? "#2E7D32" : "#9E9E9E" }
                                    GradientStop { position: 1.0; color: makeFilmBtn.enabled ? "#43A047" : "#9E9E9E" }
                                }
                                opacity: makeFilmBtn.enabled ? 1.0 : 0.6
                            }
                            contentItem: Text {
                                text: makeFilmBtn.text
                                font: makeFilmBtn.font
                                color: "#FFFFFF"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: appController.handle_uart_command("EXPORT")

                            ToolTip.visible: hovered && !enabled
                            ToolTip.text: "Cần ít nhất " + N.NeoConstants.minFrames + " tấm để tạo phim"
                        }

                        // IO3 + Enter tags
                        Column {
                            spacing: 5
                            width: 54

                            Rectangle {
                                width: parent.width
                                height: 22
                                radius: 5
                                color: "#FFFFFF"
                                border.color: "#D8C9A8"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Enter"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: "monospace"
                                    color: "#7a6200"
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 22
                                radius: 5
                                color: "#212121"
                                Text {
                                    anchors.centerIn: parent
                                    text: "IO3"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#FFFFFF"
                                    font.letterSpacing: 0.5
                                }
                            }
                        }
                    }
                }
            }
        }

        // ====================================================================
        // FILMWRAP — header "Các tấm đã chụp ◀▶" + filmstrip dải
        // ====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.bottomMargin: 4

            // Header
            RowLayout {
                spacing: 8

                Text {
                    text: "Các tấm đã chụp"
                    font.pixelSize: 13
                    font.bold: true
                    color: N.NeoConstants.textSecondary
                }

                // ◀ ▶ kbd badges
                Repeater {
                    model: ["◀", "▶"]
                    delegate: Rectangle {
                        width: arrowLabel.implicitWidth + 10
                        height: 18
                        radius: 4
                        color: "#FFFFFF"
                        border.color: "#D8C9A8"
                        border.width: 1
                        Text {
                            id: arrowLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "monospace"
                            color: "#7a6200"
                        }
                    }
                }

                Text {
                    text: "chọn tấm để xoá"
                    font.pixelSize: 13
                    font.bold: true
                    color: N.NeoConstants.textSecondary
                }
            }

            // FilmStrip (dải thumbnail)
            FilmStrip {
                id: filmStrip
                Layout.fillWidth: true
                Layout.preferredHeight: 96

                onDeleteRequested: function(frameIndex) {
                    deleteDialog.targetIndex = frameIndex
                    deleteDialog.open()
                }
            }
        }

        // ====================================================================
        // LEGEND — footer phím tắt
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#F2EAD8"

            RowLayout {
                anchors.centerIn: parent
                spacing: 18

                // Group: 3 nút cốt lõi
                RowLayout {
                    spacing: 6
                    Text {
                        text: "3 nút cốt lõi ="
                        font.pixelSize: 13
                        font.bold: true
                        color: N.NeoConstants.textPrimary
                    }
                    Repeater {
                        model: ["IO1", "IO2", "IO3"]
                        delegate: Rectangle {
                            width: ioLabel.implicitWidth + 10
                            height: 20
                            radius: 5
                            color: "#212121"
                            Text {
                                id: ioLabel
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 10
                                font.bold: true
                                color: "#FFFFFF"
                                font.letterSpacing: 0.5
                            }
                        }
                    }
                }

                Text {
                    text: "·"
                    font.pixelSize: 13
                    color: N.NeoConstants.textSecondary
                }

                // Group: keyboard
                RowLayout {
                    spacing: 6
                    Text {
                        text: "Bàn phím:"
                        font.pixelSize: 13
                        font.bold: true
                        color: N.NeoConstants.textPrimary
                    }
                    Repeater {
                        model: ["Space", "Del", "Enter", "◀▶", "C", "G", "1·2·3"]
                        delegate: Rectangle {
                            width: kbdLegendLabel.implicitWidth + 10
                            height: 20
                            radius: 5
                            color: "#FFFFFF"
                            border.color: "#D8C9A8"
                            border.width: 1
                            Text {
                                id: kbdLegendLabel
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "monospace"
                                color: "#7a6200"
                            }
                        }
                    }
                }
            }
        }
    }

    // ====================================================================
    // Keyboard shortcuts — CapturePage (T-011)
    // ====================================================================
    Keys.onPressed: function(event) {
        // Space — handled by MainWindow/Stack but also here for completeness
        if (event.key === Qt.Key_Space) {
            appController.handle_uart_command("SHOOT")
            event.accepted = true
        }
        // Delete key — "smart delete" (selected or last)
        else if (event.key === Qt.Key_Delete) {
            var idx = filmStrip.selectedIndex
            if (idx > 0) {
                deleteDialog.targetIndex = idx
                deleteDialog.open()
            } else if (N.AppState.frameCount > 0) {
                deleteDialog.targetIndex = N.AppState.frameCount
                deleteDialog.open()
            }
            event.accepted = true
        }
        // Escape — close popup or deselect filmstrip
        else if (event.key === Qt.Key_Escape) {
            if (deleteDialog.visible) {
                deleteDialog.close()
            } else if (cameraPicker.visible) {
                // handled by picker's own Esc
            } else {
                filmStrip.selectedIndex = 0
            }
            event.accepted = true
        }
        // C — open camera picker
        else if (event.key === Qt.Key_C) {
            if (!cameraPicker.visible && !deleteDialog.visible) {
                cameraPicker.openPicker(appController.get_current_webcam_index())
                event.accepted = true
            }
        }
        // G — navigate to library (T-012 hook)
        else if (event.key === Qt.Key_G) {
            if (!cameraPicker.visible && !deleteDialog.visible) {
                root.navigateToLibrary()
                event.accepted = true
            }
        }
        // 1/2/3 — speed select
        else if (event.key === Qt.Key_1) {
            appController.select_speed("Cham")
            speedFeedbackToast.show("Cham", 5)
            N.AppState.selectedSpeedLabel = "Cham"
            event.accepted = true
        }
        else if (event.key === Qt.Key_2) {
            appController.select_speed("Vua")
            speedFeedbackToast.show("Vua", 8)
            N.AppState.selectedSpeedLabel = "Vua"
            event.accepted = true
        }
        else if (event.key === Qt.Key_3) {
            appController.select_speed("Nhanh")
            speedFeedbackToast.show("Nhanh", 12)
            N.AppState.selectedSpeedLabel = "Nhanh"
            event.accepted = true
        }
        // ? or F1 — open shortcuts overlay
        else if (event.key === Qt.Key_Question || event.key === Qt.Key_F1) {
            if (shortcutsOverlay.visible) {
                shortcutsOverlay.close()
            } else {
                shortcutsOverlay.open()
            }
            event.accepted = true
        }
        // Arrow keys — filmstrip navigation
        else if (event.key === Qt.Key_Left) {
            if (filmStrip.selectedIndex > 1) {
                filmStrip.selectedIndex -= 1
            } else if (N.AppState.frameCount > 0) {
                filmStrip.selectedIndex = 1
            }
            event.accepted = true
        }
        else if (event.key === Qt.Key_Right) {
            if (filmStrip.selectedIndex < N.AppState.frameCount) {
                filmStrip.selectedIndex += 1
            }
            event.accepted = true
        }
    }

    // ====================================================================
    // Camera picker popup (T-005)
    // ====================================================================
    CameraPickerPopup {
        id: cameraPicker
        onCameraConfirmed: function(index) {
            // Live preview auto-updates via webcam_ready signal
        }
        onCancelled: {
            // Nothing extra
        }
    }

    // ====================================================================
    // Keyboard shortcuts overlay (T-011)
    // ====================================================================
    KeyboardShortcutsOverlay {
        id: shortcutsOverlay
    }

    // ====================================================================
    // Speed feedback toast (bottom-right, 1.5s)
    // ====================================================================
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

    // ====================================================================
    // Connections — refresh filmstrip on events
    // ====================================================================
    Connections {
        target: appController
        function onFrameCountChanged(n) {
            filmStrip.refresh()
            if (filmStrip.selectedIndex > n) {
                filmStrip.selectedIndex = 0
            }
        }
    }

    Connections {
        target: signalBusBridge
        function onFrameDeleted(newCount) {
            filmStrip.selectedIndex = 0
            filmStrip.refresh()
        }
        function onFrameUndone(newCount) {
            filmStrip.selectedIndex = 0
            filmStrip.refresh()
        }
        function onWebcamReady() {
            N.AppState.previewCounter++
        }
    }

    // ====================================================================
    // Delete confirmation dialog (T-010 + T-011 — mockup 04 fidelity)
    // ====================================================================
    Popup {
        id: deleteDialog

        property int targetIndex: 0

        anchors.centerIn: Overlay.overlay
        width: 480
        modal: true
        closePolicy: Popup.NoAutoClose  // we handle Esc manually

        background: Rectangle {
            color: N.NeoConstants.surface
            radius: 28
        }

        Overlay.modal: Rectangle {
            color: "#80212121"
        }

        contentItem: FocusScope {
            id: deleteScope
            focus: true
            implicitHeight: dialogContent.implicitHeight + 2 * N.NeoConstants.spacingL

            // Keyboard handling (T-011 AC4) — must live on an Item, not the Popup.
            // Esc = Thôi để lại; Enter/Del = Xoá (theo mockup 04).
            Keys.onEscapePressed: function(event) {
                deleteDialog.close()
                event.accepted = true
            }
            Keys.onReturnPressed: function(event) {
                appController.handle_delete_frame(deleteDialog.targetIndex)
                deleteDialog.close()
                event.accepted = true
            }
            Keys.onEnterPressed: function(event) {
                appController.handle_delete_frame(deleteDialog.targetIndex)
                deleteDialog.close()
                event.accepted = true
            }
            Keys.onDeletePressed: function(event) {
                appController.handle_delete_frame(deleteDialog.targetIndex)
                deleteDialog.close()
                event.accepted = true
            }

            ColumnLayout {
                id: dialogContent
                anchors.centerIn: parent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: N.NeoConstants.spacingL
                spacing: N.NeoConstants.spacingM

                // Trash emoji
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "🗑️"
                    font.pixelSize: 74
                }

                // Title
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Xoá <b><font color='" + N.NeoConstants.error + "'>tấm số " + deleteDialog.targetIndex + "</font></b> nhé?"
                    textFormat: Text.RichText
                    font.pixelSize: 34
                    font.bold: true
                    color: N.NeoConstants.textPrimary
                }

                // Subtitle
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Tấm này sẽ biến mất khỏi phim của bé."
                    font.pixelSize: 19
                    color: N.NeoConstants.textSecondary
                    font.bold: true
                }

                // Buttons row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // "Thôi, để lại" — default focus (Esc)
                    Button {
                        id: dialogCancelBtn
                        Layout.fillWidth: true
                        height: 78
                        font.pixelSize: 21
                        font.bold: true

                        background: Rectangle {
                            radius: 18
                            color: dialogCancelBtn.hovered ? "#E0E0E0" : "#FFFFFF"
                            border.color: N.NeoConstants.textSecondary
                            border.width: 3
                        }
                        contentItem: Column {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "↩️ Thôi, để lại"
                                font.pixelSize: 21
                                font.bold: true
                                color: N.NeoConstants.textSecondary
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: escLabel.implicitWidth + 14
                                height: 22
                                radius: 6
                                color: "#FFFFFF"
                                border.color: "#bbb"
                                border.width: 1
                                Text {
                                    id: escLabel
                                    anchors.centerIn: parent
                                    text: "Esc"
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: "monospace"
                                    color: N.NeoConstants.textSecondary
                                }
                            }
                        }

                        onClicked: deleteDialog.close()
                    }

                    // "Xoá đi!" — destructive (Enter or Del)
                    Button {
                        id: dialogConfirmBtn
                        Layout.fillWidth: true
                        height: 78
                        font.pixelSize: 21
                        font.bold: true

                        background: Rectangle {
                            radius: 18
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: dialogConfirmBtn.hovered ? "#B71C1C" : N.NeoConstants.error }
                                GradientStop { position: 1.0; color: dialogConfirmBtn.hovered ? "#C62828" : "#E53935" }
                            }
                        }
                        contentItem: Column {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "🗑️ Xoá đi!"
                                font.pixelSize: 21
                                font.bold: true
                                color: "#FFFFFF"
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: enterDelLabel.implicitWidth + 14
                                height: 22
                                radius: 6
                                color: "#40FFFFFF"
                                border.color: "#66FFFFFF"
                                border.width: 1
                                Text {
                                    id: enterDelLabel
                                    anchors.centerIn: parent
                                    text: "Enter  hoặc  Del"
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: "monospace"
                                    color: "#FFFFFF"
                                }
                            }
                        }

                        onClicked: {
                            appController.handle_delete_frame(deleteDialog.targetIndex)
                            deleteDialog.close()
                        }
                    }
                }
            }
        }

        // Focus the FocusScope so its Keys handler runs (Esc = thôi, Enter/Del = xoá).
        onOpened: deleteScope.forceActiveFocus()
    }

    // ====================================================================
    // Flash helper (called from MainWindow after SHOOT)
    // ====================================================================
    function flashCapture() { preview.flash() }
}
