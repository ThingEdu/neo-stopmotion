// CameraPickerPopup.qml — T-005 camera-select
// Design spec: docs/01-specs/features/camera-select/design-spec.md
//
// Live preview: uses image://picker/<counter> (PickerImageProvider in app.py)
// which reads get_probed_preview() from the currently-probed CaptureEngine.
// AppController.pickerCounter bumps each time a probe succeeds → Image reloads.
// A Timer continues to refresh the image every 33 ms while preview is active
// so the user sees a live feed rather than a single still frame.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons" as N

Popup {
    id: root

    // Signals
    signal cameraConfirmed(int index)
    signal cancelled()

    // Current webcam index when popup opens (set by caller)
    property int initialIndex: 0
    property int currentIndex: 0

    // Internal state
    property bool isAvailable: false
    property bool isLoading: false
    property bool noCamera: false  // all 0-5 fail

    // Picker preview refresh counter — we derive our own local counter from
    // appController.pickerCounter (changes when probe succeeds) combined with
    // a running Timer offset so we get genuine live video, not a one-shot snap.
    property int _baseCounter: 0      // set from appController.pickerCounter
    property int _liveOffset: 0       // incremented by liveTimer

    // -----------------------------------------------------------------
    // Popup geometry
    // -----------------------------------------------------------------
    anchors.centerIn: Overlay.overlay
    width: 520
    height: 500
    modal: true
    closePolicy: Popup.CloseOnEscape

    Overlay.modal: Rectangle {
        color: "#80000000"
    }

    background: Rectangle {
        color: N.NeoConstants.surface
        radius: 16
        border.color: N.NeoConstants.primary
        border.width: 2
    }

    // -----------------------------------------------------------------
    // Open / close animation
    // -----------------------------------------------------------------
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: N.NeoConstants.animFast }
        NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: N.NeoConstants.animFast }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
    }

    // -----------------------------------------------------------------
    // Actions (called from QML)
    // -----------------------------------------------------------------
    function openPicker(webcamIndex) {
        currentIndex = webcamIndex
        initialIndex = webcamIndex
        isAvailable = false
        isLoading = true
        noCamera = false
        _liveOffset = 0
        open()
        _probeIndex(currentIndex)
    }

    function _probeIndex(idx) {
        isLoading = true
        isAvailable = false
        _liveOffset = 0
        appController.picker_probe_index(idx)
    }

    function _goNext() {
        var next = (currentIndex + 1) % 6
        currentIndex = next
        _probeIndex(next)
    }

    function _goPrev() {
        var prev = (currentIndex - 1 + 6) % 6
        currentIndex = prev
        _probeIndex(prev)
    }

    function _confirm() {
        liveTimer.stop()
        appController.picker_confirm(currentIndex)
        cameraConfirmed(currentIndex)
        close()
    }

    function _cancel() {
        liveTimer.stop()
        appController.picker_cancel()
        cancelled()
        close()
    }

    // -----------------------------------------------------------------
    // Live-refresh timer — drives the picker preview at ~30 fps while open
    // Only runs when the probed camera is available.
    // -----------------------------------------------------------------
    Timer {
        id: liveTimer
        interval: 33
        repeat: true
        running: root.opened && root.isAvailable && !root.isLoading
        onTriggered: root._liveOffset++
    }

    // -----------------------------------------------------------------
    // Listen to AppController probe result
    // -----------------------------------------------------------------
    Connections {
        target: appController

        function onCameraProbeResult(index, available) {
            if (index !== root.currentIndex) return  // stale result — ignore
            root.isLoading = false
            root.isAvailable = available
            if (available) {
                // Sync base counter; live timer takes over from here
                root._baseCounter = appController.pickerCounter
                root._liveOffset = 0
            } else {
                liveTimer.stop()
            }
        }

        function onPickerCounterChanged(n) {
            // pickerCounter bumped by a fresh probe success — force image reload
            root._baseCounter = n
            root._liveOffset = 0
        }
    }

    // -----------------------------------------------------------------
    // Content
    // -----------------------------------------------------------------
    contentItem: FocusScope {
        id: contentScope

        // Keyboard handling inside the FocusScope avoids the Qt warning
        // "Could not attach Keys property to: CameraPickerPopup … is not an Item"
        Keys.onEscapePressed: function(event) {
            root._cancel()
            event.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: N.NeoConstants.spacingL
            spacing: N.NeoConstants.spacingM

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Chọn camera"
                    font.pixelSize: N.NeoConstants.fontBody
                    font.bold: true
                    color: N.NeoConstants.textPrimary
                    Layout.fillWidth: true
                }

                Button {
                    text: "Huỷ"
                    width: 80
                    height: 36
                    font.pixelSize: N.NeoConstants.fontCaption
                    onClicked: root._cancel()
                    background: Rectangle {
                        radius: 8
                        color: parent.hovered ? "#CCCCCC" : "#E0E0E0"
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: N.NeoConstants.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // -----------------------------------------------------------------
            // Preview area 400 × 300
            // States: Loading | Error | NoCamera | Active (live image)
            // -----------------------------------------------------------------
            Rectangle {
                id: previewArea
                Layout.alignment: Qt.AlignHCenter
                width: 400
                height: 300
                color: "#000000"
                radius: 8
                border.color: root.isAvailable ? N.NeoConstants.primary : "#E0E0E0"
                border.width: root.isAvailable ? 2 : 1
                clip: true

                // --- LIVE PREVIEW (only visible when camera available) ---
                Image {
                    id: pickerPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    // Force reload on every counter change (base from probe + live offset)
                    source: "image://picker/" + (root._baseCounter * 10000 + root._liveOffset)
                    visible: !root.isLoading && root.isAvailable && !root.noCamera

                    // Smooth fade-in when first becoming visible
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // --- LOADING STATE ---
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.isLoading

                    BusyIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: root.isLoading
                        width: 48
                        height: 48
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Đang mở camera..."
                        font.pixelSize: N.NeoConstants.fontCaption
                        color: "#FFFFFF"
                    }
                }

                // --- ERROR STATE (camera opened but unavailable) ---
                Column {
                    anchors.centerIn: parent
                    spacing: N.NeoConstants.spacingS
                    visible: !root.isLoading && !root.isAvailable && !root.noCamera

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Camera này không hoạt động"
                        font.pixelSize: N.NeoConstants.fontCaption
                        color: N.NeoConstants.warning
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Thử camera khác nhé!"
                        font.pixelSize: N.NeoConstants.fontCaption
                        color: N.NeoConstants.warning
                    }
                }

                // --- NO CAMERA STATE ---
                Column {
                    anchors.centerIn: parent
                    spacing: N.NeoConstants.spacingS
                    visible: root.noCamera

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Không tìm thấy camera nào"
                        font.pixelSize: N.NeoConstants.fontCaption
                        color: N.NeoConstants.error
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Kiểm tra dây USB rồi thử lại nhé!"
                        font.pixelSize: N.NeoConstants.fontCaption
                        color: N.NeoConstants.error
                    }
                }
            }

            // Camera indicator "Camera N / 6"
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.noCamera
                text: "Camera " + (root.currentIndex + 1) + " / 6"
                font.pixelSize: N.NeoConstants.fontBody
                font.bold: true
                color: N.NeoConstants.textPrimary
            }

            // Navigation buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: N.NeoConstants.spacingM
                visible: !root.noCamera

                Button {
                    text: "◄ Camera trước"
                    width: 190
                    height: 52
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: true
                    enabled: !root.isLoading
                    onClicked: root._goPrev()
                    background: Rectangle {
                        radius: 10
                        color: parent.hovered ? "#CCCCCC" : "#E0E0E0"
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: N.NeoConstants.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "Camera tiếp ►"
                    width: 190
                    height: 52
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: true
                    enabled: !root.isLoading
                    onClicked: root._goNext()
                    background: Rectangle {
                        radius: 10
                        color: parent.hovered ? "#CCCCCC" : "#E0E0E0"
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: N.NeoConstants.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Close button — only shown when no camera found at any index
            Button {
                Layout.alignment: Qt.AlignHCenter
                visible: root.noCamera
                text: "Đóng"
                width: 200
                height: 52
                font.pixelSize: N.NeoConstants.fontCaption
                onClicked: root._cancel()
                background: Rectangle {
                    radius: 10
                    color: parent.hovered ? "#CCCCCC" : "#E0E0E0"
                }
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: N.NeoConstants.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Confirm button
            Button {
                id: confirmBtn
                Layout.fillWidth: true
                height: 56
                visible: !root.noCamera
                enabled: root.isAvailable && !root.isLoading
                text: "CHỌN CAMERA NÀY"
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                onClicked: root._confirm()

                background: Rectangle {
                    radius: 12
                    color: {
                        if (!confirmBtn.enabled) return "#9E9E9E"
                        if (confirmBtn.hovered) return "#E64A19"
                        return N.NeoConstants.primary
                    }
                    opacity: confirmBtn.enabled ? 1.0 : 0.6
                }
                contentItem: Text {
                    text: confirmBtn.text
                    font: confirmBtn.font
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // Grab focus when opened so keyboard shortcuts work immediately
    onOpened: contentScope.forceActiveFocus()
}
