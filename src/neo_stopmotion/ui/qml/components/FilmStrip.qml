// FilmStrip.qml — Dải thumbnail ngang cho frame-review-delete (T-004)
// Design: docs/01-specs/features/frame-review-delete/design-spec.md
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons" as N

Rectangle {
    id: root

    // ---------------------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------------------

    // List of file:// paths (with cache-busting suffix) — set from CapturePage
    property var framePaths: []

    // Currently selected index (1-based; 0 = nothing selected)
    property int selectedIndex: 0

    // Read-only: expose selected to parent
    readonly property int currentSelectedIndex: selectedIndex

    // Signals to CapturePage
    signal deleteRequested(int frameIndex)  // 1-based index the user wants to delete

    // ---------------------------------------------------------------------------
    // Appearance
    // ---------------------------------------------------------------------------

    height: 120
    radius: 12
    color: N.NeoConstants.surface
    border.width: selectedIndex > 0 ? 2 : 1
    border.color: selectedIndex > 0 ? N.NeoConstants.primary : "#E0E0E0"

    // Internal refresh helper: reload paths from controller
    function refresh() {
        root.framePaths = appController.get_frame_paths()
    }

    // Keyboard navigation — left/right arrows, Delete, Escape
    Keys.onLeftPressed: {
        if (selectedIndex > 1) selectedIndex -= 1
    }
    Keys.onRightPressed: {
        if (selectedIndex < framePaths.length) selectedIndex += 1
    }
    Keys.onDeletePressed: {
        if (selectedIndex > 0) root.deleteRequested(selectedIndex)
    }
    Keys.onEscapePressed: {
        selectedIndex = 0
    }

    // ---------------------------------------------------------------------------
    // Empty-state placeholder
    // ---------------------------------------------------------------------------

    Text {
        anchors.centerIn: parent
        visible: root.framePaths.length === 0
        text: "Chụp tấm đầu tiên đi!"
        font.pixelSize: N.NeoConstants.fontCaption
        color: N.NeoConstants.textSecondary
    }

    // ---------------------------------------------------------------------------
    // Thumbnail ListView
    // ---------------------------------------------------------------------------

    ListView {
        id: listView
        visible: root.framePaths.length > 0

        anchors {
            left: parent.left
            right: deleteBtn.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: N.NeoConstants.spacingM
            rightMargin: N.NeoConstants.spacingS
            topMargin: N.NeoConstants.spacingS
            bottomMargin: N.NeoConstants.spacingS
        }

        orientation: ListView.Horizontal
        spacing: N.NeoConstants.spacingS
        clip: true
        model: root.framePaths

        // Auto-scroll to end on new frame
        onCountChanged: {
            if (count > 0) positionViewAtEnd()
        }

        ScrollBar.horizontal: ScrollBar {
            height: 4
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                color: N.NeoConstants.primary
                opacity: 0.4
                radius: 2
            }
        }

        delegate: Item {
            id: thumbItem

            // modelData is "file://...?t=..." path
            required property string modelData
            required property int index

            // 1-based index for this delegate
            readonly property int frameNum: index + 1
            readonly property bool isSelected: root.selectedIndex === frameNum

            width: 96   // 80px thumb + 8px padding each side
            height: listView.height

            // Animate scale on selection (selection border drawn by thumbContainer)
            scale: isSelected ? 1.08 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 150 }
            }

            Column {
                anchors.centerIn: parent
                spacing: 4

                // Thumbnail image
                Rectangle {
                    id: thumbContainer
                    width: 80
                    height: 60
                    radius: 8
                    color: "#F0F0F0"  // placeholder bg
                    border.width: thumbItem.isSelected ? 3 : (thumbMouse.containsMouse ? 2 : 0)
                    border.color: thumbItem.isSelected
                        ? N.NeoConstants.primary
                        : N.NeoConstants.warning

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: thumbItem.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false   // disable QML cache — spec §8b cache-busting
                        smooth: true
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: 7
                        }
                    }
                }

                // Frame number label
                Text {
                    width: 80
                    horizontalAlignment: Text.AlignHCenter
                    text: thumbItem.frameNum
                    font.pixelSize: N.NeoConstants.fontCaption
                    font.bold: false
                    color: thumbItem.isSelected
                        ? N.NeoConstants.primary
                        : N.NeoConstants.textSecondary
                }
            }

            // Mouse area — click to select; hover for border
            MouseArea {
                id: thumbMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.selectedIndex = thumbItem.frameNum
                    root.forceActiveFocus()
                }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Delete button — fixed on the right
    // ---------------------------------------------------------------------------

    Rectangle {
        id: deleteBtn
        width: 160
        height: 56
        radius: 12
        anchors {
            right: parent.right
            rightMargin: N.NeoConstants.spacingM
            verticalCenter: parent.verticalCenter
        }

        color: {
            if (root.selectedIndex === 0) return "#9E9E9E"
            return deleteMouse.containsMouse ? "#B71C1C" : N.NeoConstants.error
        }
        opacity: root.selectedIndex === 0 ? 0.35 : 1.0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: "🗑"   // U+1F5D1 wastebasket
                font.pixelSize: N.NeoConstants.fontCaption
                color: "#FFFFFF"
            }
            Text {
                text: "XOÁ TẤM NÀY"
                font.pixelSize: N.NeoConstants.fontCaption
                font.bold: true
                color: "#FFFFFF"
            }
        }

        MouseArea {
            id: deleteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.selectedIndex === 0 ? Qt.ArrowCursor : Qt.PointingHandCursor
            enabled: root.selectedIndex > 0
            onClicked: {
                if (root.selectedIndex > 0) {
                    root.deleteRequested(root.selectedIndex)
                }
            }
        }
    }
}
