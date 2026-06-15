// SuccessPage.qml — T-007 save-video: "Lưu video" + "Sao chép link" buttons
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

    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: N.NeoConstants.spacingL
        spacing: N.NeoConstants.spacingM

        // Branded header
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: N.NeoConstants.spacingM

            Image {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                source: resourcesUrl + "/images/maker_viet_logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Maker Việt × ThingEdu"
                    font.pixelSize: N.NeoConstants.fontBody
                    font.bold: true
                    color: N.NeoConstants.primary
                }
                Text {
                    text: "NEO One — Trạm Làm Phim"
                    font.pixelSize: N.NeoConstants.fontCaption
                    color: N.NeoConstants.textSecondary
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "🎉 Phim của bạn đã xong!"
            font.pixelSize: N.NeoConstants.fontTitle
            font.bold: true
            color: N.NeoConstants.success
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: N.NeoConstants.spacingL

            // Left: video preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "black"
                radius: 12
                border.color: N.NeoConstants.primary
                border.width: 3

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
                    anchors.margins: 8
                }
            }

            // Right: QR + share URL + action buttons (T-007)
            ColumnLayout {
                Layout.preferredWidth: 420
                Layout.fillHeight: true
                spacing: N.NeoConstants.spacingM

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.qrPath !== "" ? "📱 Mời bạn quét mã" : "💾 Phim đã lưu trên máy"
                    font.pixelSize: N.NeoConstants.fontBody
                    font.bold: true
                    color: N.NeoConstants.textPrimary
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    // T-007: QR flexible height 280-360 to make room for buttons
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 300
                    color: "white"
                    border.color: N.NeoConstants.primary
                    border.width: 2
                    radius: 8
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
                    Layout.preferredWidth: 400
                    text: root.shareUrl !== "" ? root.shareUrl : ""
                    font.pixelSize: N.NeoConstants.fontCaption
                    color: N.NeoConstants.secondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAnywhere
                    visible: root.shareUrl !== ""
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 400
                    text: "Phim lưu tại: " + root.mp4Path
                    font.pixelSize: 12
                    color: N.NeoConstants.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAnywhere
                    visible: root.mp4Path !== ""
                }

                // Spacer
                Item { Layout.preferredHeight: N.NeoConstants.spacingM }

                // -----------------------------------------------------------------
                // T-007: "Lưu video" button — secondary (#1565C0)
                // -----------------------------------------------------------------
                Button {
                    id: saveVideoBtn
                    Layout.fillWidth: true
                    height: 52

                    // States: normal / loading / success / disabled
                    property string btnState: root.mp4Path !== "" ? "normal" : "disabled"

                    enabled: root.mp4Path !== "" && btnState !== "loading"

                    text: {
                        if (btnState === "loading") return "Đang lưu..."
                        if (btnState === "success") return "✓  Đã lưu!"
                        return "↓  Lưu video"
                    }
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: true

                    background: Rectangle {
                        radius: 10
                        opacity: saveVideoBtn.enabled ? 1.0 : 0.5
                        color: {
                            if (!saveVideoBtn.enabled) return "#9E9E9E"
                            if (saveVideoBtn.btnState === "success") return N.NeoConstants.success
                            if (saveVideoBtn.hovered) return "#0D47A1"
                            return N.NeoConstants.secondary
                        }
                    }
                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent
                        BusyIndicator {
                            visible: saveVideoBtn.btnState === "loading"
                            running: saveVideoBtn.btnState === "loading"
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: saveVideoBtn.text
                            font: saveVideoBtn.font
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    ToolTip.visible: hovered && !enabled
                    ToolTip.text: "Chưa có phim để lưu"

                    onClicked: _openSaveDialog()

                    Timer {
                        id: saveSuccessTimer
                        interval: 1500
                        onTriggered: saveVideoBtn.btnState = "normal"
                    }
                }

                // -----------------------------------------------------------------
                // T-007: "Sao chép link" button — visible only when shareUrl != ""
                // -----------------------------------------------------------------
                Button {
                    id: copyLinkBtn
                    Layout.fillWidth: true
                    height: 52
                    visible: root.shareUrl !== ""

                    property bool copied: false

                    text: copied ? "✓  Đã sao chép!" : "🔗  Sao chép link"
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: true

                    background: Rectangle {
                        radius: 10
                        color: copyLinkBtn.hovered || copyLinkBtn.copied
                            ? "#E3F2FD"
                            : "transparent"
                        border.color: copyLinkBtn.copied
                            ? N.NeoConstants.success
                            : N.NeoConstants.secondary
                        border.width: 1
                    }
                    contentItem: Text {
                        text: copyLinkBtn.text
                        font: copyLinkBtn.font
                        color: copyLinkBtn.copied
                            ? N.NeoConstants.success
                            : N.NeoConstants.secondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

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
            }
        }

        // Footer hint + reset button
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: N.NeoConstants.spacingL

            Text {
                text: "💡 Mời bạn bấm nút để làm lại phim"
                font.pixelSize: N.NeoConstants.fontCaption
                color: N.NeoConstants.warning
            }

            Button {
                Layout.preferredHeight: N.NeoConstants.buttonHeight
                Layout.preferredWidth: 280
                text: "🔁  Làm phim mới"
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                highlighted: true
                onClicked: appController.reset_session()
            }
        }
    }

    // ---------------------------------------------------------------------------
    // T-007: save_video_result handler — show toast
    // ---------------------------------------------------------------------------
    Connections {
        target: signalBusBridge
        function onSaveVideoResult(success, message) {
            if (message === "Đã sao chép link!") {
                // Already handled by copyLinkBtn state
                return
            }
            if (message === "__cancelled__") {
                // User closed file dialog without choosing — just reset button
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
    // T-007: Native file dialog + file copy trigger
    // Note: QFileDialog cannot be called from QML directly across all platforms.
    // We call a Python slot that opens QFileDialog in the main thread.
    // ---------------------------------------------------------------------------
    function _openSaveDialog() {
        saveVideoBtn.btnState = "loading"
        // Python opens QFileDialog (blocking, main thread) and handles copy async
        appController.open_save_dialog(root.mp4Path)
    }

    // ---------------------------------------------------------------------------
    // T-007: Toast notification (bottom-right)
    // ---------------------------------------------------------------------------
    Rectangle {
        id: saveToast
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: N.NeoConstants.spacingL
        width: Math.min(toastMsg.implicitWidth + 32, 480)
        height: toastMsg.implicitHeight + 24
        radius: 8
        color: _isError ? "#E5C62828" : "#E5212121"
        opacity: 0
        visible: opacity > 0

        property bool _isError: false
        property string _message: ""

        function show(success, msg) {
            _isError = !success
            _message = (success ? "✓  " : "⚠️  ") + msg
            opacity = 0.9
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
