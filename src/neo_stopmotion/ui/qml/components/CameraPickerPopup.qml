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

    // Dynamic model from enumerate scan (replaces hardcoded 6-slot carousel)
    // Each element is a real camera index (e.g. [0] or [0,1])
    property var availableIndices: []

    // Internal state
    property bool isAvailable: false
    property bool isLoading: false
    property bool noCamera: false  // true when availableIndices is empty

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
        initialIndex = webcamIndex
        isAvailable = false
        isLoading = true
        noCamera = false
        availableIndices = []
        _liveOffset = 0
        open()
        // Enumerate real cameras first; then probe the first available
        _scanAndProbe()
    }

    function _scanAndProbe() {
        isLoading = true
        isAvailable = false
        var indices = appController.get_available_camera_indices()
        availableIndices = indices
        if (indices.length === 0) {
            isLoading = false
            noCamera = true
        } else {
            noCamera = false
            // Start at the initially-selected index if it is in the list,
            // otherwise fall back to the first available.
            var startReal = indices[0]
            for (var i = 0; i < indices.length; i++) {
                if (indices[i] === initialIndex) { startReal = indices[i]; break }
            }
            currentIndex = startReal
            _probeIndex(currentIndex)
        }
    }

    function _probeIndex(idx) {
        isLoading = true
        isAvailable = false
        _liveOffset = 0
        appController.picker_probe_index(idx)
    }

    function _goNext() {
        if (availableIndices.length === 0) return
        var pos = availableIndices.indexOf(currentIndex)
        var nextPos = (pos + 1) % availableIndices.length
        var next = availableIndices[nextPos]
        currentIndex = next
        _probeIndex(next)
    }

    function _goPrev() {
        if (availableIndices.length === 0) return
        var pos = availableIndices.indexOf(currentIndex)
        var prevPos = (pos - 1 + availableIndices.length) % availableIndices.length
        var prev = availableIndices[prevPos]
        currentIndex = prev
        _probeIndex(prev)
    }

    function _rescan() {
        hotplugTimer.stop()
        isLoading = true
        isAvailable = false
        noCamera = false
        availableIndices = []
        _scanAndProbe()
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
    // Hot-plug re-scan Timer — only active when popup is open AND no camera
    // found. Stops immediately when a camera is detected.
    // CONSTRAINT: MUST NOT run when popup is closed or cameras are present.
    // -----------------------------------------------------------------
    Timer {
        id: hotplugTimer
        interval: 2000
        repeat: true
        running: root.opened && root.noCamera
        onTriggered: {
            var indices = appController.get_available_camera_indices()
            if (indices.length > 0) {
                hotplugTimer.stop()
                root.availableIndices = indices
                root.noCamera = false
                root.currentIndex = indices[0]
                root._probeIndex(indices[0])
            }
        }
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
        Keys.onReturnPressed: function(event) {
            if (root.isAvailable && !root.isLoading) {
                root._confirm()
                event.accepted = true
            }
        }
        Keys.onEnterPressed: function(event) {
            if (root.isAvailable && !root.isLoading) {
                root._confirm()
                event.accepted = true
            }
        }
        Keys.onLeftPressed: function(event) {
            if (!root.isLoading) {
                root._goPrev()
                event.accepted = true
            }
        }
        Keys.onRightPressed: function(event) {
            if (!root.isLoading) {
                root._goNext()
                event.accepted = true
            }
        }
        Keys.onPressed: function(event) {
            // 1–M: jump directly to camera by position in availableIndices list
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                var pos = event.key - Qt.Key_1  // 0-based position
                if (pos < root.availableIndices.length) {
                    var idx = root.availableIndices[pos]
                    root.currentIndex = idx
                    root._probeIndex(idx)
                    event.accepted = true
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: N.NeoConstants.spacingL
            spacing: N.NeoConstants.spacingM

            // Header
            RowLayout {
                Layout.fillWidth: true

                // Icon + title (mockup 03 style)
                RowLayout {
                    spacing: 12
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 12
                        color: "#E3F0FF"
                        Text {
                            anchors.centerIn: parent
                            text: "📷"
                            font.pixelSize: 24
                        }
                    }
                    Text {
                        text: "Chọn camera"
                        font.pixelSize: N.NeoConstants.fontBody
                        font.bold: true
                        color: N.NeoConstants.textPrimary
                    }
                    Layout.fillWidth: true
                }

                Item { Layout.fillWidth: true }

                Button {
                    height: 46
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: true
                    onClicked: root._cancel()
                    background: Rectangle {
                        radius: 12
                        color: parent.hovered ? "#CCCCCC" : "#FFFFFF"
                        border.color: "#dddddd"
                        border.width: 2
                    }
                    contentItem: RowLayout {
                        spacing: 6
                        Text {
                            text: "✕ Huỷ"
                            font.pixelSize: N.NeoConstants.fontCaption
                            font.bold: true
                            color: N.NeoConstants.textSecondary
                        }
                        Rectangle {
                            width: escKbd.implicitWidth + 10
                            height: 20
                            radius: 5
                            color: "#FFFFFF"
                            border.color: "#D8C9A8"
                            border.width: 1
                            Text {
                                id: escKbd
                                anchors.centerIn: parent
                                text: "Esc"
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "monospace"
                                color: "#7a6200"
                            }
                        }
                    }
                    leftPadding: 14
                    rightPadding: 14
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
                        text: "Cắm camera USB vào rồi bấm Quét lại nhé!"
                        font.pixelSize: N.NeoConstants.fontCaption
                        color: N.NeoConstants.error
                    }
                    Item { height: 8; width: 1 }
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Quét lại"
                        width: 140
                        height: 44
                        font.pixelSize: N.NeoConstants.fontCaption
                        font.bold: true
                        onClicked: root._rescan()
                        background: Rectangle {
                            radius: 10
                            color: parent.hovered ? Qt.lighter(N.NeoConstants.secondary, 1.7) : "#E3F0FF"
                            border.color: N.NeoConstants.secondary
                            border.width: 2
                        }
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: N.NeoConstants.secondary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // Camera indicator "Camera N / M" — dynamic count from real enumerate
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.noCamera
                text: "Camera " + (root.availableIndices.indexOf(root.currentIndex) + 1) + " / " + root.availableIndices.length
                font.pixelSize: N.NeoConstants.fontBody
                font.bold: true
                color: N.NeoConstants.textPrimary
            }

            // Navigation buttons + dot indicators (mockup 03)
            RowLayout {
                Layout.fillWidth: true
                spacing: N.NeoConstants.spacingM
                visible: !root.noCamera

                Button {
                    Layout.fillWidth: true
                    height: 64
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: true
                    enabled: !root.isLoading
                    onClicked: root._goPrev()

                    background: Rectangle {
                        radius: 16
                        color: parent.hovered ? Qt.lighter(N.NeoConstants.secondary, 1.8) : "#FFFFFF"
                        border.color: N.NeoConstants.secondary
                        border.width: 2
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        anchors.centerIn: parent
                        Rectangle {
                            width: prevKbd.implicitWidth + 10
                            height: 22
                            radius: 5
                            color: "#FFFFFF"
                            border.color: "#c9d3dd"
                            border.width: 1
                            Text {
                                id: prevKbd
                                anchors.centerIn: parent
                                text: "◀"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "monospace"
                                color: N.NeoConstants.secondary
                            }
                        }
                        Text {
                            text: "Camera trước"
                            font.pixelSize: N.NeoConstants.fontCaption
                            font.bold: true
                            color: N.NeoConstants.secondary
                        }
                    }
                }

                // Dot indicators — one dot per real camera found
                Row {
                    spacing: 8
                    Repeater {
                        model: root.availableIndices.length
                        delegate: Rectangle {
                            // index = position in list; check if this position's real camera
                            // index matches currentIndex
                            property bool isActive: root.availableIndices[index] === root.currentIndex
                            width: isActive ? 30 : 12
                            height: 12
                            radius: 6
                            color: isActive ? N.NeoConstants.secondary : "#dddddd"
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    height: 64
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: true
                    enabled: !root.isLoading
                    onClicked: root._goNext()

                    background: Rectangle {
                        radius: 16
                        color: parent.hovered ? Qt.lighter(N.NeoConstants.secondary, 1.8) : "#FFFFFF"
                        border.color: N.NeoConstants.secondary
                        border.width: 2
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        anchors.centerIn: parent
                        Text {
                            text: "Camera sau"
                            font.pixelSize: N.NeoConstants.fontCaption
                            font.bold: true
                            color: N.NeoConstants.secondary
                        }
                        Rectangle {
                            width: nextKbd.implicitWidth + 10
                            height: 22
                            radius: 5
                            color: "#FFFFFF"
                            border.color: "#c9d3dd"
                            border.width: 1
                            Text {
                                id: nextKbd
                                anchors.centerIn: parent
                                text: "▶"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "monospace"
                                color: N.NeoConstants.secondary
                            }
                        }
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

            // Confirm button (mockup 03: blue gradient + Enter kbd badge)
            Button {
                id: confirmBtn
                Layout.fillWidth: true
                height: 72
                visible: !root.noCamera
                enabled: root.isAvailable && !root.isLoading
                font.pixelSize: N.NeoConstants.fontButton
                font.bold: true
                onClicked: root._confirm()

                background: Rectangle {
                    radius: 18
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: confirmBtn.enabled ? "#1565C0" : "#9E9E9E" }
                        GradientStop { position: 1.0; color: confirmBtn.enabled ? "#1E88E5" : "#9E9E9E" }
                    }
                    opacity: confirmBtn.enabled ? 1.0 : 0.6
                }
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "✓ DÙNG CAMERA NÀY"
                        font.pixelSize: N.NeoConstants.fontButton
                        font.bold: true
                        color: "#FFFFFF"
                    }
                    Rectangle {
                        width: confirmKbd.implicitWidth + 10
                        height: 24
                        radius: 6
                        color: "#FFFFFF"
                        border.color: "#FFFFFF"
                        border.width: 1
                        Text {
                            id: confirmKbd
                            anchors.centerIn: parent
                            text: "Enter"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "monospace"
                            color: N.NeoConstants.secondary
                        }
                    }
                }
            }

            // Key hint legend (mockup 03 bottom)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                visible: !root.noCamera

                Repeater {
                    model: [
                        { keys: "◀  ▶", desc: "đổi camera" },
                        { keys: "1–9",  desc: "chọn nhanh" },
                        { keys: "Enter",desc: "xác nhận" },
                        { keys: "Esc",  desc: "huỷ" }
                    ]
                    delegate: RowLayout {
                        spacing: 6
                        Rectangle {
                            width: kbdHintLabel.implicitWidth + 10
                            height: 20
                            radius: 5
                            color: "#FFFFFF"
                            border.color: "#c9d3dd"
                            border.width: 1
                            Text {
                                id: kbdHintLabel
                                anchors.centerIn: parent
                                text: modelData.keys
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "monospace"
                                color: N.NeoConstants.secondary
                            }
                        }
                        Text {
                            text: modelData.desc
                            font.pixelSize: 13
                            font.bold: true
                            color: N.NeoConstants.textSecondary
                        }
                    }
                }
            }
        }
    }

    // Grab focus when opened so keyboard shortcuts work immediately
    onOpened: contentScope.forceActiveFocus()
}
