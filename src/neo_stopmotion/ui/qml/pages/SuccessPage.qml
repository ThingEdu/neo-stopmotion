// SuccessPage.qml — T-007 save-video + T-011 keyboard shortcuts
// Mockup: docs/03-codebase/design/brand/html-mockups/06-success.html
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../singletons" as N

Item {
    id: root
    property string mp4Path: ""
    property string gifPath: ""
    property string shareUrl: ""
    property string qrPath: ""

    // Signal for T-012 (library navigation) — T-012 sẽ connect
    signal navigateToLibrary()

    // ---------------------------------------------------------------------------
    // Background (mockup 06 radial gradient)
    // ---------------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FFFFFF" }
            GradientStop { position: 0.6; color: "#FFF3D6" }
            GradientStop { position: 1.0; color: "#FFE0B2" }
        }
    }

    // Confetti decorations (mockup 06)
    Text { text: "🎉"; font.pixelSize: 40; opacity: 0.55; x: 80; y: 70 }
    Text { text: "⭐"; font.pixelSize: 40; opacity: 0.55; anchors.right: parent.right; anchors.rightMargin: 100; y: 110 }
    Text { text: "✨"; font.pixelSize: 40; opacity: 0.55; x: 55; y: 200 }
    Text { text: "🎊"; font.pixelSize: 40; opacity: 0.55; anchors.right: parent.right; anchors.rightMargin: 280; y: 55 }

    // ---------------------------------------------------------------------------
    // Main layout
    // ---------------------------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Title (mockup 06)
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            Layout.topMargin: 22

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "🎉 Phim của bé đã xong!"
                font.pixelSize: 42
                font.bold: true
                color: N.NeoConstants.success
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Cùng xem lại thành quả nào 🍿"
                font.pixelSize: 20
                color: N.NeoConstants.textSecondary
                font.bold: true
            }
        }

        // Video + side panel
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 50
            Layout.rightMargin: 50
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            spacing: 34

            // Video card (4:3 ratio, mockup 06)
            Rectangle {
                Layout.preferredWidth: 540
                Layout.preferredHeight: 405  // 4:3 of 540
                Layout.alignment: Qt.AlignVCenter
                radius: 22
                color: "#2e3a44"
                border.color: "#FFFFFF"
                border.width: 5
                clip: true

                MediaPlayer {
                    id: player
                    source: root.mp4Path !== "" ? "file://" + root.mp4Path : ""
                    videoOutput: vo
                    audioOutput: AudioOutput { volume: 0 }
                    loops: MediaPlayer.Infinite
                    onSourceChanged: if (root.mp4Path !== "") play()
                    Component.onCompleted: if (root.mp4Path !== "") play()
                }
                VideoOutput {
                    id: vo
                    anchors.fill: parent
                    anchors.margins: 4
                }

                // Loop badge (top-left)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 16
                    height: 32
                    width: loopLabel.implicitWidth + 24
                    radius: 999
                    color: "#80000000"
                    Text {
                        id: loopLabel
                        anchors.centerIn: parent
                        text: "🔁 Đang phát"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#FFFFFF"
                    }
                }

                // Space play/pause hint (bottom-centre, mockup 06)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 16
                    height: 32
                    width: ppRow.implicitWidth + 20
                    radius: 999
                    color: "#80000000"

                    RowLayout {
                        id: ppRow
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: spacePPKbd.implicitWidth + 10
                            height: 20
                            radius: 5
                            color: "#FFFFFF"
                            border.color: "#2E000000"
                            border.width: 1
                            Text {
                                id: spacePPKbd
                                anchors.centerIn: parent
                                text: "Space"
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "monospace"
                                color: N.NeoConstants.secondary
                            }
                        }
                        Text {
                            text: "phát / tạm dừng"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }
                }
            }

            // Side panel: QR + URL
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 380
                spacing: 16

                // QR card
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 300
                    height: qrCardContent.implicitHeight + 36
                    radius: 22
                    color: "#FFFFFF"

                    ColumnLayout {
                        id: qrCardContent
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 210
                            height: 210
                            radius: 14
                            border.color: N.NeoConstants.primary
                            border.width: 2
                            color: "white"
                            visible: root.qrPath !== ""

                            Image {
                                anchors.fill: parent
                                anchors.margins: 8
                                source: root.qrPath !== "" ? "file://" + root.qrPath : ""
                                fillMode: Image.PreserveAspectFit
                                cache: false
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.qrPath !== "" ? "📱 Quét mã để xem & tải phim" : "💾 Phim đã lưu trên máy"
                            font.pixelSize: 16
                            font.bold: true
                            color: N.NeoConstants.textSecondary
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            visible: root.shareUrl !== ""
                            width: shareUrlLabel.implicitWidth + 28
                            height: 32
                            radius: 10
                            color: "#E3F0FF"

                            Text {
                                id: shareUrlLabel
                                anchors.centerIn: parent
                                text: root.shareUrl
                                font.pixelSize: 15
                                font.bold: true
                                color: N.NeoConstants.secondary
                            }
                        }
                    }
                }

                // MP4 path (small)
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 380
                    text: root.mp4Path !== "" ? "Phim lưu tại: " + root.mp4Path : ""
                    font.pixelSize: 12
                    color: N.NeoConstants.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAnywhere
                    visible: root.mp4Path !== ""
                }
            }
        }

        // ----------------------------------------------------------------
        // Action buttons (mockup 06: Lưu / Sao chép / Thư viện / Làm mới)
        // ----------------------------------------------------------------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 12
            spacing: 14

            // Lưu video — S
            Button {
                id: saveVideoBtn
                height: 72
                font.pixelSize: 19
                font.bold: true

                property string btnState: root.mp4Path !== "" ? "normal" : "disabled"
                enabled: root.mp4Path !== "" && btnState !== "loading"

                background: Rectangle {
                    radius: 18
                    color: saveVideoBtn.hovered ? "#E3F0FF" : "#FFFFFF"
                    border.color: N.NeoConstants.secondary
                    border.width: 3
                    opacity: saveVideoBtn.enabled ? 1.0 : 0.5
                }
                contentItem: Column {
                    anchors.centerIn: parent
                    spacing: 3
                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        BusyIndicator {
                            visible: saveVideoBtn.btnState === "loading"
                            running: saveVideoBtn.btnState === "loading"
                            width: 18
                            height: 18
                        }
                        Text {
                            text: {
                                if (saveVideoBtn.btnState === "loading") return "Đang lưu..."
                                if (saveVideoBtn.btnState === "success") return "✓ Đã lưu!"
                                return "↓ Lưu video"
                            }
                            font.pixelSize: 19
                            font.bold: true
                            color: saveVideoBtn.btnState === "success"
                                ? N.NeoConstants.success
                                : N.NeoConstants.secondary
                        }
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: saveKbd.implicitWidth + 10
                        height: 20
                        radius: 5
                        color: "#FFFFFF"
                        border.color: "#2E000000"
                        border.width: 1
                        Text {
                            id: saveKbd
                            anchors.centerIn: parent
                            text: "S"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "monospace"
                            color: N.NeoConstants.secondary
                        }
                    }
                }
                leftPadding: 22
                rightPadding: 22

                onClicked: _openSaveDialog()

                Timer {
                    id: saveSuccessTimer
                    interval: 1500
                    onTriggered: saveVideoBtn.btnState = "normal"
                }
            }

            // Sao chép link — L
            Button {
                id: copyLinkBtn
                height: 72
                visible: root.shareUrl !== ""
                font.pixelSize: 19
                font.bold: true

                property bool copied: false

                background: Rectangle {
                    radius: 18
                    color: copyLinkBtn.hovered || copyLinkBtn.copied ? "#E3F0FF" : "#FFFFFF"
                    border.color: copyLinkBtn.copied ? N.NeoConstants.success : N.NeoConstants.secondary
                    border.width: 3
                }
                contentItem: Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: copyLinkBtn.copied ? "✓ Đã sao chép!" : "🔗 Sao chép link"
                        font.pixelSize: 19
                        font.bold: true
                        color: copyLinkBtn.copied ? N.NeoConstants.success : N.NeoConstants.secondary
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: copyKbd.implicitWidth + 10
                        height: 20
                        radius: 5
                        color: "#FFFFFF"
                        border.color: "#2E000000"
                        border.width: 1
                        Text {
                            id: copyKbd
                            anchors.centerIn: parent
                            text: "L"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "monospace"
                            color: N.NeoConstants.secondary
                        }
                    }
                }
                leftPadding: 22
                rightPadding: 22

                onClicked: {
                    appController.copy_link(root.shareUrl)
                    copyLinkBtn.copied = true
                    copySuccessTimer.restart()
                }

                Timer {
                    id: copySuccessTimer
                    interval: 1500
                    onTriggered: copyLinkBtn.copied = false
                }
            }

            // Phim đã làm — G (hook for T-012)
            Button {
                id: libraryBtn
                height: 72
                font.pixelSize: 19
                font.bold: true

                background: Rectangle {
                    radius: 18
                    color: libraryBtn.hovered ? "#E3F0FF" : "#FFFFFF"
                    border.color: N.NeoConstants.secondary
                    border.width: 3
                }
                contentItem: Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "📁 Phim đã làm"
                        font.pixelSize: 19
                        font.bold: true
                        color: N.NeoConstants.secondary
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: libKbd.implicitWidth + 10
                        height: 20
                        radius: 5
                        color: "#FFFFFF"
                        border.color: "#2E000000"
                        border.width: 1
                        Text {
                            id: libKbd
                            anchors.centerIn: parent
                            text: "G"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "monospace"
                            color: N.NeoConstants.secondary
                        }
                    }
                }
                leftPadding: 22
                rightPadding: 22

                onClicked: root.navigateToLibrary()
            }

            // Làm phim mới — N / Enter
            Button {
                id: newFilmBtn
                height: 80
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
                    spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "🔁 Làm phim mới"
                        font.pixelSize: 22
                        font.bold: true
                        color: "#FFFFFF"
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: newKbd.implicitWidth + 10
                        height: 20
                        radius: 5
                        color: "#40FFFFFF"
                        border.color: "#66FFFFFF"
                        border.width: 1
                        Text {
                            id: newKbd
                            anchors.centerIn: parent
                            text: "N / Enter"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "monospace"
                            color: "#FFFFFF"
                        }
                    }
                }
                leftPadding: 34
                rightPadding: 34

                onClicked: appController.reset_session()
            }
        }

        // Footer keyboard legend (mockup 06)
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 18
            text: "Space phát/dừng · S lưu · L chép link · G thư viện · N/Enter làm phim mới"
            font.pixelSize: 13
            font.bold: true
            color: N.NeoConstants.textSecondary
        }
    }

    // ---------------------------------------------------------------------------
    // Keyboard shortcuts — T-011 AC5
    // ---------------------------------------------------------------------------
    Keys.onPressed: function(event) {
        // Space — play/pause
        if (event.key === Qt.Key_Space) {
            if (player.playbackState === MediaPlayer.PlayingState) {
                player.pause()
            } else {
                player.play()
            }
            event.accepted = true
        }
        // S — save video
        else if (event.key === Qt.Key_S) {
            if (root.mp4Path !== "") _openSaveDialog()
            event.accepted = true
        }
        // L — copy link
        else if (event.key === Qt.Key_L) {
            if (root.shareUrl !== "") {
                appController.copy_link(root.shareUrl)
                copyLinkBtn.copied = true
                copySuccessTimer.restart()
            }
            event.accepted = true
        }
        // G — library (T-012 hook)
        else if (event.key === Qt.Key_G) {
            root.navigateToLibrary()
            event.accepted = true
        }
        // N or Enter — new film
        else if (event.key === Qt.Key_N ||
                 event.key === Qt.Key_Return ||
                 event.key === Qt.Key_Enter) {
            appController.reset_session()
            event.accepted = true
        }
    }

    // ---------------------------------------------------------------------------
    // T-007: save_video_result handler
    // ---------------------------------------------------------------------------
    Connections {
        target: signalBusBridge
        function onSaveVideoResult(success, message) {
            if (message === "Đã sao chép link!") {
                return
            }
            if (message === "__cancelled__") {
                saveVideoBtn.btnState = "normal"
                return
            }
            saveToast.show(success, message)
            if (success) {
                saveVideoBtn.btnState = "success"
                saveSuccessTimer.restart()
            } else {
                saveVideoBtn.btnState = "normal"
            }
        }
    }

    // ---------------------------------------------------------------------------
    // T-007: Native file dialog
    // ---------------------------------------------------------------------------
    function _openSaveDialog() {
        saveVideoBtn.btnState = "loading"
        appController.open_save_dialog(root.mp4Path)
    }

    // ---------------------------------------------------------------------------
    // T-007: Toast notification
    // ---------------------------------------------------------------------------
    Rectangle {
        id: saveToast
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: N.NeoConstants.spacingL
        width: Math.min(toastMsg.implicitWidth + 32, 480)
        height: toastMsg.implicitHeight + 24
        radius: 14
        color: _isError ? "#E5C62828" : N.NeoConstants.success
        opacity: 0
        visible: opacity > 0

        property bool _isError: false
        property string _message: ""

        function show(success, msg) {
            _isError = !success
            _message = (success ? "✓  " : "⚠️  ") + msg
            opacity = 0.95
            toastHideTimer.interval = success ? 4000 : 6000
            toastHideTimer.restart()
        }

        Text {
            id: toastMsg
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            text: saveToast._message
            font.pixelSize: N.NeoConstants.fontCaption
            font.bold: true
            color: "#FFFFFF"
            wrapMode: Text.WrapAnywhere
        }

        Timer {
            id: toastHideTimer
            onTriggered: saveToast.opacity = 0
        }

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
