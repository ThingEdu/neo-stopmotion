// LibraryPage.qml — T-012 Thư viện phim
// Mockup: docs/03-codebase/design/brand/html-mockups/07-library.html
// Master-detail: grid (trái) + detail pane (phải)
// Điều khiển 100% bằng bàn phím: ◀▶▲▼ chọn · Enter xem · S lưu · L chép link · Del xoá · Esc thoát
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../singletons" as N

Item {
    id: root
    focus: true

    // ---------------------------------------------------------------------------
    // State
    // ---------------------------------------------------------------------------
    property var sessions: []          // list of QVariantMap from library_list_sessions()
    property int selectedIndex: 0      // currently selected card index (0-based)
    property bool isPlaying: false     // player state
    property bool isLoading: true      // scan in progress
    property string errorMessage: ""   // dir-level error (§4.5)

    // Delete confirmation state: 0=none, 1=step1, 2=step2
    property int deleteStep: 0

    // Toast
    property string toastMsg: ""
    property bool toastIsError: false

    // Computed
    readonly property var currentSession: sessions.length > 0 && selectedIndex >= 0
        ? sessions[Math.min(selectedIndex, sessions.length - 1)]
        : null

    // ---------------------------------------------------------------------------
    // Load data on appear
    // ---------------------------------------------------------------------------
    Component.onCompleted: _loadSessions()

    // Safety net: if this page is popped/destroyed while a video is playing,
    // stop + release the MediaPlayer first (destroying a live MediaPlayer can
    // crash the Qt multimedia backend natively).
    Component.onDestruction: _stopPlayer()

    function _loadSessions() {
        isLoading = true
        errorMessage = ""
        var raw = []
        try {
            raw = appController.library_list_sessions()
        } catch (e) {
            errorMessage = "Không thể mở thư mục dự án. Kiểm tra lại cài đặt."
            isLoading = false
            return
        }
        if (raw === null || raw === undefined) {
            errorMessage = "Không thể mở thư mục dự án. Kiểm tra lại cài đặt."
            isLoading = false
            return
        }
        sessions = raw
        selectedIndex = 0
        isLoading = false
        if (sessions.length > 0) {
            filmGrid.forceActiveFocus()
        }
    }

    // ---------------------------------------------------------------------------
    // Background
    // ---------------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: N.NeoConstants.background
    }

    // ---------------------------------------------------------------------------
    // Main vertical layout: header | body | footer
    // ---------------------------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================================
        // HEADER (mockup 07: brand + film count + back + help)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: 62
            color: N.NeoConstants.surface
            // bottom border
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

                // Brand
                RowLayout {
                    spacing: 12

                    Rectangle {
                        width: 38; height: 38
                        radius: 11
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: N.NeoConstants.secondary }
                            GradientStop { position: 1.0; color: "#1E88E5" }
                        }
                        Text { anchors.centerIn: parent; text: "📁"; font.pixelSize: 20 }
                    }
                    Text {
                        text: "Phim đã làm"
                        font.pixelSize: 22; font.bold: true
                        color: N.NeoConstants.textPrimary
                    }
                    Rectangle {
                        height: 28
                        width: countLabel.implicitWidth + 20
                        radius: 999
                        color: "#F2EAD8"
                        Text {
                            id: countLabel
                            anchors.centerIn: parent
                            text: {
                                var n = sessions.filter(function(s) { return !s.is_error }).length
                                return n + " phim"
                            }
                            font.pixelSize: 15; font.bold: true
                            color: N.NeoConstants.textSecondary
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right buttons
                RowLayout {
                    spacing: 10

                    Button {
                        id: backBtn
                        height: 46
                        font.pixelSize: N.NeoConstants.fontCaption; font.bold: true
                        background: Rectangle {
                            radius: 13; color: "white"
                            border.color: N.NeoConstants.textSecondary; border.width: 2
                        }
                        contentItem: Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "← Quay lại chụp"; font.pixelSize: 15; font.bold: true; color: N.NeoConstants.textSecondary; verticalAlignment: Text.AlignVCenter }
                            Rectangle {
                                width: escKbd.implicitWidth + 10; height: 22; radius: 5
                                color: "white"; border.color: "#c9d3dd"; border.width: 2
                                Text { id: escKbd; anchors.centerIn: parent; text: "Esc"; font.pixelSize: 12; font.bold: true; font.family: "monospace"; color: N.NeoConstants.secondary }
                            }
                        }
                        leftPadding: 14; rightPadding: 14
                        onClicked: { _stopPlayer(); root.navigateBack() }
                    }

                    Button {
                        id: helpBtn
                        height: 46
                        background: Rectangle { radius: 13; color: "#F2EAD8"; border.width: 0 }
                        contentItem: Row {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "⌨️ Phím tắt"; font.pixelSize: 14; font.bold: true; color: N.NeoConstants.textSecondary; verticalAlignment: Text.AlignVCenter }
                            Rectangle {
                                width: helpKbd.implicitWidth + 10; height: 22; radius: 5
                                color: "white"; border.color: "#c9d3dd"; border.width: 2
                                Text { id: helpKbd; anchors.centerIn: parent; text: "?"; font.pixelSize: 12; font.bold: true; font.family: "monospace"; color: N.NeoConstants.secondary }
                            }
                        }
                        leftPadding: 13; rightPadding: 13
                        onClicked: shortcutOverlay.visible = !shortcutOverlay.visible
                    }
                }
            }
        }

        // ====================================================================
        // BODY — list (left) + detail (right)
        // ====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ----------------------------------------------------------------
            // LEFT: film grid (2 columns)
            // ----------------------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Loading state
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    visible: isLoading
                    BusyIndicator { anchors.horizontalCenter: parent.horizontalCenter; running: true; width: 48; height: 48 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Đang tải danh sách phim..."; font.pixelSize: 16; color: N.NeoConstants.textSecondary; font.bold: true }
                }

                // Error state (§4.5) — dir unreadable
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    visible: !isLoading && errorMessage !== ""
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⚠️"; font.pixelSize: 54 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: errorMessage; font.pixelSize: 16; color: N.NeoConstants.error; font.bold: true; wrapMode: Text.WordWrap; width: 300; horizontalAlignment: Text.AlignHCenter }
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Thử lại"
                        font.pixelSize: 16; font.bold: true
                        height: 44
                        background: Rectangle { radius: 12; color: N.NeoConstants.secondary }
                        contentItem: Text { anchors.centerIn: parent; text: parent.text; font: parent.font; color: "white" }
                        onClicked: _loadSessions()
                    }
                }

                // Empty state (§4.2)
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    visible: !isLoading && errorMessage === "" && sessions.length === 0
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📽️"; font.pixelSize: 64 }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Chưa có phim nào.\nHãy làm phim đầu tiên nhé!"
                        font.pixelSize: 18; font.bold: true
                        color: N.NeoConstants.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap; width: 300
                    }
                }

                // Grid of film cards (§4.4)
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 0
                    visible: !isLoading && errorMessage === "" && sessions.length > 0
                    clip: true

                    GridView {
                        id: filmGrid
                        anchors.fill: parent
                        anchors.margins: 18
                        cellWidth: (width - 14) / 2
                        cellHeight: 118
                        keyNavigationEnabled: false  // We handle keys manually for correctness
                        focus: !isLoading && sessions.length > 0

                        // Navigation hint
                        header: Item {
                            width: filmGrid.width
                            height: 36
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: "◀  ▶  ▲  ▼ di chuyển  ·  Enter xem phim đang chọn"
                                font.pixelSize: 13; font.bold: true
                                color: N.NeoConstants.textSecondary
                            }
                        }

                        model: sessions

                        delegate: Item {
                            width: filmGrid.cellWidth - 14
                            height: filmGrid.cellHeight - 14
                            x: 7; y: 7

                            readonly property var sess: sessions[index]
                            readonly property bool isSelected: index === root.selectedIndex

                            Rectangle {
                                id: card
                                anchors.fill: parent
                                radius: 16
                                color: N.NeoConstants.surface
                                border.color: isSelected ? N.NeoConstants.primary : "transparent"
                                border.width: isSelected ? 3 : 0
                                clip: true

                                // Card shadow (selected state)
                                layer.enabled: isSelected
                                layer.effect: null

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    // Thumbnail (104×78)
                                    Rectangle {
                                        width: 104; height: 78
                                        radius: 11
                                        clip: true
                                        color: "#2e3a44"

                                        // Error state: warning icon
                                        Text {
                                            anchors.centerIn: parent
                                            text: "⚠️"
                                            font.pixelSize: 36
                                            visible: sess.is_error
                                        }

                                        // Placeholder when no thumbnail
                                        Text {
                                            anchors.centerIn: parent
                                            text: "📽️"
                                            font.pixelSize: 36
                                            visible: !sess.is_error && sess.thumbnail_path === ""
                                        }

                                        Image {
                                            anchors.fill: parent
                                            source: !sess.is_error && sess.thumbnail_path !== ""
                                                ? "file://" + sess.thumbnail_path : ""
                                            fillMode: Image.PreserveAspectCrop
                                            cache: false
                                            visible: !sess.is_error && sess.thumbnail_path !== ""
                                        }

                                        // Duration badge
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            height: 20
                                            width: durLabel.implicitWidth + 10
                                            radius: 6
                                            color: "#99000000"
                                            visible: !sess.is_error
                                            Text {
                                                id: durLabel
                                                anchors.centerIn: parent
                                                text: sess.duration_label
                                                font.pixelSize: 11; font.bold: true
                                                color: "white"
                                            }
                                        }
                                    }

                                    // Meta column
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 3

                                        Text {
                                            Layout.fillWidth: true
                                            text: sess.title
                                            font.pixelSize: 17; font.bold: true
                                            color: N.NeoConstants.textPrimary
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: "🗓️ " + sess.date_label
                                            font.pixelSize: 13; font.bold: true
                                            color: N.NeoConstants.textSecondary
                                        }
                                        Row {
                                            spacing: 6
                                            // Frames badge
                                            Rectangle {
                                                height: 22; radius: 6
                                                width: fcLabel.implicitWidth + 12
                                                color: "#FFF3D6"
                                                Text {
                                                    id: fcLabel
                                                    anchors.centerIn: parent
                                                    text: sess.frame_count + " tấm"
                                                    font.pixelSize: 11; font.bold: true
                                                    color: "#7a6200"
                                                }
                                            }
                                            // Share badge
                                            Rectangle {
                                                height: 22; radius: 6
                                                width: shLabel.implicitWidth + 12
                                                color: sess.download_url !== "" ? "#E8F5E9" : "#ECEFF1"
                                                Text {
                                                    id: shLabel
                                                    anchors.centerIn: parent
                                                    text: sess.download_url !== "" ? "🔗 Đã chia sẻ" : "💾 Trên máy"
                                                    font.pixelSize: 11; font.bold: true
                                                    color: sess.download_url !== "" ? N.NeoConstants.success : "#546E7A"
                                                }
                                            }
                                        }
                                    }
                                }

                                // Mouse click to select
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.selectedIndex = index
                                        filmGrid.forceActiveFocus()
                                        deleteStep = 0
                                        _stopPlayer()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // RIGHT: detail panel (470 px, mockup 07)
            // ----------------------------------------------------------------
            Rectangle {
                Layout.preferredWidth: 470
                Layout.fillHeight: true
                color: "#FFFDF6"
                // left border
                Rectangle {
                    anchors.top: parent.top; anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: 2; color: "#FFE0B2"
                }

                // Empty / no selection
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: currentSession === null
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📽️"; font.pixelSize: 54 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Chọn một phim để xem"; font.pixelSize: 16; font.bold: true; color: N.NeoConstants.textSecondary }
                }

                // Detail content when session selected
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12
                    visible: currentSession !== null

                    // Player
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        radius: 18
                        color: "#2e3a44"
                        clip: true
                        border.color: "white"; border.width: 4

                        MediaPlayer {
                            id: videoPlayer
                            videoOutput: videoOutput
                            audioOutput: AudioOutput { volume: 0 }
                            loops: MediaPlayer.Infinite
                        }
                        VideoOutput {
                            id: videoOutput
                            anchors.fill: parent
                            anchors.margins: 4
                            visible: isPlaying
                        }

                        // Poster (thumbnail when not playing)
                        Image {
                            anchors.fill: parent
                            source: currentSession && !isPlaying && currentSession.thumbnail_path !== ""
                                ? "file://" + currentSession.thumbnail_path : ""
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            visible: !isPlaying && currentSession !== null && currentSession.thumbnail_path !== ""
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "📽️"; font.pixelSize: 80; opacity: 0.7
                            visible: !isPlaying && (currentSession === null || currentSession.thumbnail_path === "")
                        }

                        // Play icon overlay when not playing
                        Rectangle {
                            anchors.centerIn: parent
                            width: 78; height: 78; radius: 39
                            color: "#EBFFFFFF"
                            visible: !isPlaying
                            Text {
                                anchors.centerIn: parent
                                text: "▶"; font.pixelSize: 34
                                color: N.NeoConstants.primary
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: _playVideo()
                            }
                        }

                        // Play/pause hint at bottom
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 12
                            height: 30
                            width: ppHint.implicitWidth + 20
                            radius: 999
                            color: "#80000000"
                            Text {
                                id: ppHint
                                anchors.centerIn: parent
                                text: isPlaying ? "Space / Enter — tạm dừng" : "Enter / Space — phát"
                                font.pixelSize: 12; font.bold: true
                                color: "white"
                            }
                        }
                    }

                    // Film title
                    Text {
                        Layout.fillWidth: true
                        text: currentSession ? currentSession.title : ""
                        font.pixelSize: 24; font.bold: true
                        color: N.NeoConstants.textPrimary
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }

                    // Info table (mockup 07: 8 rows)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: 14
                        color: N.NeoConstants.surface
                        Layout.preferredHeight: infoCol.implicitHeight + 12

                        Column {
                            id: infoCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }

                            // Helper repeater for info rows
                            Repeater {
                                model: currentSession ? _buildInfoRows(currentSession) : []
                                delegate: Rectangle {
                                    width: infoCol.width
                                    height: 42
                                    color: "transparent"
                                    // bottom divider (all but last)
                                    Rectangle {
                                        visible: index < infoCol.children.length - 1
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left; anchors.right: parent.right
                                        height: 1; color: "#f0f0f0"
                                    }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8; anchors.rightMargin: 8
                                        Text {
                                            Layout.preferredWidth: 160
                                            text: modelData.key
                                            font.pixelSize: 15; font.bold: true
                                            color: N.NeoConstants.textSecondary
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            Layout.maximumWidth: 220
                                            text: modelData.value
                                            font.pixelSize: 15; font.bold: true
                                            color: modelData.url ? N.NeoConstants.secondary : N.NeoConstants.textPrimary
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideLeft
                                            font.family: modelData.mono ? "monospace" : ""
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Action buttons (mockup 07: Xem / Lưu lại / Chép link / Xoá)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        spacing: 10

                        // Xem / play button
                        Button {
                            id: playBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: currentSession !== null && !currentSession.is_error
                            background: Rectangle {
                                radius: 14
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#2E7D32" }
                                    GradientStop { position: 1.0; color: "#43A047" }
                                }
                                opacity: playBtn.enabled ? 1.0 : 0.4
                            }
                            contentItem: Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: isPlaying ? "⏸ Dừng" : "▶ Xem phim"; font.pixelSize: 16; font.bold: true; color: "white" }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: playKbd.implicitWidth + 10; height: 20; radius: 5
                                    color: "#40FFFFFF"; border.color: "#66FFFFFF"; border.width: 1
                                    Text { id: playKbd; anchors.centerIn: parent; text: "Enter"; font.pixelSize: 11; font.bold: true; font.family: "monospace"; color: "white" }
                                }
                            }
                            onClicked: _togglePlay()
                        }

                        // Lưu lại
                        Button {
                            id: saveBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: currentSession !== null && !currentSession.is_error
                            background: Rectangle {
                                radius: 14; color: saveBtn.hovered ? "#E3F0FF" : "white"
                                border.color: N.NeoConstants.secondary; border.width: 2
                                opacity: saveBtn.enabled ? 1.0 : 0.4
                            }
                            contentItem: Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "↓ Lưu lại"; font.pixelSize: 16; font.bold: true; color: N.NeoConstants.secondary }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: saveKbdL.implicitWidth + 10; height: 20; radius: 5
                                    color: "white"; border.color: "#2E000000"; border.width: 1
                                    Text { id: saveKbdL; anchors.centerIn: parent; text: "S"; font.pixelSize: 11; font.bold: true; font.family: "monospace"; color: N.NeoConstants.secondary }
                                }
                            }
                            onClicked: _saveSession()
                        }

                        // Chép link
                        Button {
                            id: copyBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: currentSession !== null && currentSession.download_url !== ""
                            background: Rectangle {
                                radius: 14; color: copyBtn.hovered ? "#E3F0FF" : "white"
                                border.color: N.NeoConstants.secondary; border.width: 2
                                opacity: copyBtn.enabled ? 1.0 : 0.4
                            }
                            contentItem: Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🔗 Chép link"; font.pixelSize: 16; font.bold: true; color: N.NeoConstants.secondary }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: copyKbdL.implicitWidth + 10; height: 20; radius: 5
                                    color: "white"; border.color: "#2E000000"; border.width: 1
                                    Text { id: copyKbdL; anchors.centerIn: parent; text: "L"; font.pixelSize: 11; font.bold: true; font.family: "monospace"; color: N.NeoConstants.secondary }
                                }
                            }
                            onClicked: _copyLink()
                        }

                        // Xoá
                        Button {
                            id: delBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: currentSession !== null
                            background: Rectangle {
                                radius: 14; color: delBtn.hovered ? "#FFEBEE" : "white"
                                border.color: N.NeoConstants.error; border.width: 2
                                opacity: delBtn.enabled ? 1.0 : 0.4
                            }
                            contentItem: Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🗑️ Xoá phim"; font.pixelSize: 16; font.bold: true; color: N.NeoConstants.error }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: delKbdL.implicitWidth + 10; height: 20; radius: 5
                                    color: "white"; border.color: "#2E000000"; border.width: 1
                                    Text { id: delKbdL; anchors.centerIn: parent; text: "Del"; font.pixelSize: 11; font.bold: true; font.family: "monospace"; color: N.NeoConstants.error }
                                }
                            }
                            onClicked: _startDelete()
                        }
                    }
                }
            }
        }

        // ====================================================================
        // FOOTER: keyboard legend (mockup 07)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: "#F2EAD8"

            Row {
                anchors.centerIn: parent
                spacing: 16

                Repeater {
                    model: [
                        { label: "◀ ▶ ▲ ▼", desc: "chọn phim" },
                        { label: "Enter", desc: "xem" },
                        { label: "S", desc: "lưu lại" },
                        { label: "L", desc: "chép link" },
                        { label: "Del", desc: "xoá phim" },
                        { label: "Esc", desc: "quay lại chụp" },
                    ]
                    delegate: Row {
                        spacing: 5
                        Rectangle {
                            height: 24; radius: 7
                            width: kbdKey.implicitWidth + 14
                            color: "white"; border.color: "#c9d3dd"; border.width: 2
                            Text { id: kbdKey; anchors.centerIn: parent; text: modelData.label; font.pixelSize: 12; font.bold: true; font.family: "monospace"; color: N.NeoConstants.secondary }
                        }
                        Text { text: modelData.desc; font.pixelSize: 13; font.bold: true; color: N.NeoConstants.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Delete confirmation dialogs (§7.4 — 2 steps)
    // ---------------------------------------------------------------------------

    // Step 1 confirmation
    Rectangle {
        id: confirmStep1
        anchors.fill: parent
        color: "#80000000"
        visible: deleteStep === 1

        Rectangle {
            anchors.centerIn: parent
            width: 480; height: dialogCol1.implicitHeight + 48
            radius: 20
            color: N.NeoConstants.surface

            Column {
                id: dialogCol1
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "🗑️ Xoá phim này?"
                    font.pixelSize: 24; font.bold: true
                    color: N.NeoConstants.textPrimary
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Con có muốn xoá phim \"" + (currentSession ? currentSession.title : "") + "\" không?"
                    font.pixelSize: 16; font.bold: true
                    color: N.NeoConstants.textSecondary
                    wrapMode: Text.WordWrap; width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Button {
                        text: "Thôi"
                        height: 50; width: 140
                        font.pixelSize: 16; font.bold: true
                        background: Rectangle { radius: 12; color: "white"; border.color: "#c9d3dd"; border.width: 2 }
                        contentItem: Text { anchors.centerIn: parent; text: parent.text; font: parent.font; color: N.NeoConstants.textSecondary }
                        onClicked: deleteStep = 0
                    }
                    Button {
                        text: "Xoá"
                        height: 50; width: 140
                        font.pixelSize: 16; font.bold: true
                        background: Rectangle { radius: 12; color: N.NeoConstants.error }
                        contentItem: Text { anchors.centerIn: parent; text: parent.text; font: parent.font; color: "white" }
                        onClicked: deleteStep = 2
                    }
                }
            }
        }
    }

    // Step 2 confirmation (extra protection for children)
    Rectangle {
        id: confirmStep2
        anchors.fill: parent
        color: "#99000000"
        visible: deleteStep === 2

        Rectangle {
            anchors.centerIn: parent
            width: 480; height: dialogCol2.implicitHeight + 48
            radius: 20
            color: N.NeoConstants.surface

            Column {
                id: dialogCol2
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⚠️ Chắc chắn xoá?"
                    font.pixelSize: 24; font.bold: true
                    color: N.NeoConstants.error
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Xoá phim này sẽ mất vĩnh viễn, không lấy lại được. Xoá thật không?"
                    font.pixelSize: 16; font.bold: true
                    color: N.NeoConstants.textSecondary
                    wrapMode: Text.WordWrap; width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Button {
                        text: "Huỷ"
                        height: 50; width: 140
                        font.pixelSize: 16; font.bold: true
                        background: Rectangle { radius: 12; color: "white"; border.color: "#c9d3dd"; border.width: 2 }
                        contentItem: Text { anchors.centerIn: parent; text: parent.text; font: parent.font; color: N.NeoConstants.textSecondary }
                        onClicked: deleteStep = 0
                    }
                    Button {
                        text: "Xoá thật"
                        height: 50; width: 140
                        font.pixelSize: 16; font.bold: true
                        background: Rectangle {
                            radius: 12
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#B71C1C" }
                                GradientStop { position: 1.0; color: N.NeoConstants.error }
                            }
                        }
                        contentItem: Text { anchors.centerIn: parent; text: parent.text; font: parent.font; color: "white" }
                        onClicked: _confirmDelete()
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Keyboard shortcuts overlay (? key)
    // ---------------------------------------------------------------------------
    Rectangle {
        id: shortcutOverlay
        anchors.fill: parent
        color: "#99000000"
        visible: false
        z: 100

        Rectangle {
            anchors.centerIn: parent
            width: 520
            height: shortcutContent.implicitHeight + 48
            radius: 20
            color: N.NeoConstants.surface

            Column {
                id: shortcutContent
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⌨️ Phím tắt thư viện phim"
                    font.pixelSize: 22; font.bold: true; color: N.NeoConstants.textPrimary
                }

                Repeater {
                    model: [
                        { key: "◀ ▶ ▲ ▼", desc: "Di chuyển chọn phim trong lưới" },
                        { key: "Enter", desc: "Xem / toggle play-pause" },
                        { key: "Space", desc: "Toggle play-pause khi đang phát" },
                        { key: "S", desc: "Lưu lại phim đang chọn" },
                        { key: "L", desc: "Chép link (nếu có download_url)" },
                        { key: "Del", desc: "Bắt đầu luồng xoá (2 bước)" },
                        { key: "Esc", desc: "Quay lại trang chụp" },
                        { key: "?", desc: "Đóng bảng này" },
                    ]
                    delegate: RowLayout {
                        width: shortcutContent.width
                        Rectangle {
                            Layout.preferredWidth: 120; height: 30; radius: 7
                            color: "#F2EAD8"
                            Text { anchors.centerIn: parent; text: modelData.key; font.pixelSize: 14; font.bold: true; font.family: "monospace"; color: N.NeoConstants.secondary }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.desc; font.pixelSize: 15; font.bold: true
                            color: N.NeoConstants.textSecondary
                            leftPadding: 12
                        }
                    }
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Đóng  (?)"
                    height: 42; width: 140
                    font.pixelSize: 15; font.bold: true
                    background: Rectangle { radius: 12; color: "#F2EAD8" }
                    contentItem: Text { anchors.centerIn: parent; text: parent.text; font: parent.font; color: N.NeoConstants.textSecondary }
                    onClicked: shortcutOverlay.visible = false
                }
            }
        }
        MouseArea { anchors.fill: parent; onClicked: shortcutOverlay.visible = false; z: -1 }
    }

    // ---------------------------------------------------------------------------
    // Toast
    // ---------------------------------------------------------------------------
    Rectangle {
        id: toastRect
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: N.NeoConstants.spacingL
        width: Math.min(toastText.implicitWidth + 32, 500)
        height: toastText.implicitHeight + 24
        radius: 14
        color: toastIsError ? N.NeoConstants.error : N.NeoConstants.success
        opacity: 0
        visible: opacity > 0

        Text {
            id: toastText
            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            text: toastMsg
            font.pixelSize: 15; font.bold: true; color: "white"
            wrapMode: Text.WrapAnywhere
        }
        Timer {
            id: toastTimer
            onTriggered: toastRect.opacity = 0
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ---------------------------------------------------------------------------
    // Keyboard handling (§8 + domain state machine)
    // ---------------------------------------------------------------------------
    Keys.onPressed: function(event) {
        // If shortcut overlay is open, only Esc or ? closes it
        if (shortcutOverlay.visible) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Question) {
                shortcutOverlay.visible = false
                event.accepted = true
            }
            return
        }

        // Delete confirmation dialogs intercept Enter + Esc
        if (deleteStep === 1) {
            if (event.key === Qt.Key_Escape) { deleteStep = 0; event.accepted = true }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { deleteStep = 2; event.accepted = true }
            return
        }
        if (deleteStep === 2) {
            if (event.key === Qt.Key_Escape) { deleteStep = 0; event.accepted = true }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { _confirmDelete(); event.accepted = true }
            return
        }

        var cols = 2
        var total = sessions.length

        if (event.key === Qt.Key_Left) {
            if (selectedIndex % cols > 0) { _select(selectedIndex - 1) }
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            if (selectedIndex % cols < cols - 1 && selectedIndex + 1 < total) { _select(selectedIndex + 1) }
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (selectedIndex - cols >= 0) { _select(selectedIndex - cols) }
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            if (selectedIndex + cols < total) { _select(selectedIndex + cols) }
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentSession !== null && !currentSession.is_error) { _togglePlay() }
            event.accepted = true
        } else if (event.key === Qt.Key_Space) {
            if (isPlaying) {
                videoPlayer.pause(); isPlaying = false
            } else if (currentSession !== null && !currentSession.is_error) {
                _playVideo()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_S) {
            if (currentSession !== null && !currentSession.is_error) { _saveSession() }
            event.accepted = true
        } else if (event.key === Qt.Key_L) {
            if (currentSession !== null && currentSession.download_url !== "") { _copyLink() }
            event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
            if (currentSession !== null) { _startDelete() }
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            _stopPlayer()
            // Navigation back — handled via signal from MainWindow (stub here)
            console.log("[LibraryPage] Esc → back to CapturePage")
            root.navigateBack()
            event.accepted = true
        } else if (event.key === Qt.Key_Question) {
            shortcutOverlay.visible = !shortcutOverlay.visible
            event.accepted = true
        }
    }

    // Signal for navigation back
    signal navigateBack()

    // ---------------------------------------------------------------------------
    // Helper functions
    // ---------------------------------------------------------------------------

    function _select(idx) {
        _stopPlayer()
        selectedIndex = idx
        deleteStep = 0
        filmGrid.positionViewAtIndex(idx, GridView.Contain)
    }

    function _playVideo() {
        if (currentSession === null || currentSession.is_error) return
        var mp4 = currentSession.mp4_path
        if (mp4 === "") {
            _showToast("File phim MP4 không tìm thấy!", true)
            return
        }
        videoPlayer.source = "file://" + mp4
        videoPlayer.play()
        isPlaying = true
    }

    function _stopPlayer() {
        videoPlayer.stop()
        videoPlayer.source = ""   // fully release pipeline before any destroy
        isPlaying = false
    }

    function _togglePlay() {
        if (isPlaying) {
            videoPlayer.pause()
            isPlaying = false
        } else {
            _playVideo()
        }
    }

    function _saveSession() {
        if (currentSession === null || currentSession.is_error) return
        appController.library_save_session(
            currentSession.mp4_path,
            currentSession.gif_path,
            currentSession.qr_path
        )
    }

    function _copyLink() {
        if (currentSession === null || currentSession.download_url === "") return
        appController.copy_link(currentSession.download_url)
        _showToast("Đã chép link! Gán vào bất kỳ đâu để chia sẻ.", false)
    }

    function _startDelete() {
        if (currentSession === null) return
        _stopPlayer()
        deleteStep = 1
    }

    function _confirmDelete() {
        if (currentSession === null) return
        var sid = currentSession.session_id
        deleteStep = 0
        var ok = appController.library_delete_session(sid)
        if (ok) {
            // Remove from local list and select neighbour
            var newList = sessions.filter(function(s) { return s.session_id !== sid })
            sessions = newList
            if (newList.length > 0) {
                selectedIndex = Math.min(selectedIndex, newList.length - 1)
            } else {
                selectedIndex = 0
            }
            _stopPlayer()
        } else {
            _showToast("Không thể xoá phim. Kiểm tra lại quyền thư mục.", true)
        }
    }

    function _showToast(msg, isError) {
        toastMsg = (isError ? "⚠️  " : "✓  ") + msg
        toastIsError = isError
        toastRect.opacity = 0.95
        toastTimer.interval = isError ? 6000 : 3000
        toastTimer.restart()
    }

    function _buildInfoRows(sess) {
        var rows = [
            { key: "🗓️ Ngày tạo",    value: sess.date_label,      mono: false, url: false },
            { key: "🖼️ Số tấm",       value: sess.frame_count + " tấm", mono: false, url: false },
            { key: "⏱️ Thời lượng",   value: sess.duration_label,  mono: false, url: false },
            { key: "🐇 Tốc độ",       value: sess.fps_label,        mono: false, url: false },
            { key: "💽 Dung lượng",   value: sess.size_label,       mono: false, url: false },
        ]
        if (sess.download_url !== "") {
            rows.push({ key: "🔗 Link chia sẻ", value: sess.download_url, mono: false, url: true })
        }
        if (sess.mp4_path !== "") {
            // Show parent directory (monospace)
            var parts = sess.mp4_path.split("/")
            parts.pop() // remove filename
            var dir = parts.join("/") + "/"
            rows.push({ key: "📂 Lưu tại", value: dir, mono: true, url: false })
        }
        return rows
    }

    // ---------------------------------------------------------------------------
    // React to save/copy results from bus
    // ---------------------------------------------------------------------------
    Connections {
        target: signalBusBridge
        function onSaveVideoResult(success, message) {
            if (message === "__cancelled__") return
            _showToast(success ? message : message, !success)
        }
    }
}
