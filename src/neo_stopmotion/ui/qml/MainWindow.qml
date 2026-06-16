import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "singletons" as N
import "pages" as Pages

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    visible: true
    visibility: Window.Windowed
    title: "NeoStopMotion — Trạm 6"
    color: N.NeoConstants.background

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: splashComponent
        focus: true

        // Global key handler — cốt lõi 3 phím IO (T-011 AC1)
        // CapturePage handles its own extended keys (C, G, 1/2/3, ?, arrows).
        // Space and Enter are kept here so they work on any page in the stack.
        // T-012: LibraryPage overrides Enter/Space for player — skip global handler when on Library.
        Keys.onPressed: function(event) {
            // Don't forward SHOOT/EXPORT commands when LibraryPage is active
            var onLibrary = stack.currentItem && stack.currentItem.toString().indexOf("LibraryPage") !== -1
            if (onLibrary) {
                return  // LibraryPage handles all keys itself
            }
            if (event.key === Qt.Key_Space) {
                appController.handle_uart_command("SHOOT")
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                appController.handle_uart_command("EXPORT")
                event.accepted = true
            }
            // Note: Delete key is handled per-page (CapturePage: smart delete;
            // SuccessPage: no-op at stack level so page handles it).
        }
    }

    Component {
        id: splashComponent
        Pages.SplashScreen {
            onFinished: stack.replace(capturePageComponent)
        }
    }

    Component {
        id: capturePageComponent
        Pages.CapturePage {
            onNavigateToLibrary: {
                stack.push(libraryPageComponent)
            }
        }
    }

    // T-012: LibraryPage component
    Component {
        id: libraryPageComponent
        Pages.LibraryPage {
            onNavigateBack: {
                stack.pop()
            }
        }
    }

    Component {
        id: exportingPageComponent
        Pages.ExportingPage { }
    }

    Component {
        id: successPageComponent
        Pages.SuccessPage {
            onNavigateToLibrary: {
                stack.push(libraryPageComponent)
            }
        }
    }

    Connections {
        target: appController
        function onFrameCountChanged(n) {
            N.AppState.frameCount = n
        }
    }

    Connections {
        target: signalBusBridge
        function onExportStarted() {
            stack.replace(exportingPageComponent)
        }
        function onExportProgress(p) {
            if (stack.currentItem && stack.currentItem.progress !== undefined) {
                stack.currentItem.progress = p
                if (p < 0.5) {
                    stack.currentItem.statusText = "Đang ghép phim MP4..."
                } else if (p < 0.95) {
                    stack.currentItem.statusText = "Đang tạo GIF..."
                } else {
                    stack.currentItem.statusText = "Sắp xong..."
                }
            }
        }
        function onExportCompleted(mp4Path, gifPath, shareUrl, qrPath) {
            stack.replace(successPageComponent, {
                mp4Path: mp4Path,
                gifPath: gifPath,
                shareUrl: shareUrl,
                qrPath: qrPath,
            })
        }
        function onExportFailed(msg) {
            console.log("Export failed:", msg)
            stack.replace(capturePageComponent)
        }
        function onSessionReset() {
            stack.replace(capturePageComponent)
        }
        function onStatusMessage(level, message) {
            console.log("STATUS [" + level + "] " + message)
        }
    }
}
