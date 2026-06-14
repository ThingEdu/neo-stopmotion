import os
import shutil
import sys
from pathlib import Path
from PyQt6.QtCore import QObject, QTimer, QUrl, pyqtSignal
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine
from loguru import logger

from neo_stopmotion.config.settings import AppSettings, load_settings
from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError
from neo_stopmotion.core.cloud_uploader import CloudUploader
from neo_stopmotion.core.synthetic_capture import SyntheticCaptureEngine
from neo_stopmotion.core.video_exporter import VideoExporter
from neo_stopmotion.hardware.uart_listener import UARTListener
from neo_stopmotion.hardware.uart_simulator import UARTSimulator
from neo_stopmotion.services.app_controller import AppController
from neo_stopmotion.services.export_service import ExportService
from neo_stopmotion.services.session_service import SessionService
from neo_stopmotion.ui.image_provider import PreviewImageProvider
from neo_stopmotion.ui.qml_loader import find_qml_root, main_qml_path
from neo_stopmotion.utils.logging_config import configure_logging
from neo_stopmotion.utils.signal_bus import SignalBus


class _SignalBusBridge(QObject):
    """Bridge SignalBus signals to QML-friendly QObject signals."""

    uartConnected = pyqtSignal()
    uartDisconnected = pyqtSignal()
    webcamReady = pyqtSignal()
    webcamError = pyqtSignal(str)
    frameCaptured = pyqtSignal(int, str)
    frameUndone = pyqtSignal(int)
    frameDeleted = pyqtSignal(int)  # new_count after delete_frame
    sessionReset = pyqtSignal()
    exportStarted = pyqtSignal()
    exportProgress = pyqtSignal(float)
    exportCompleted = pyqtSignal(str, str, str, str)  # mp4_path, gif_path, share_url, qr_path
    exportFailed = pyqtSignal(str)
    statusMessage = pyqtSignal(str, str)

    def __init__(self, bus: SignalBus) -> None:
        super().__init__()
        bus.uart_reconnected.connect(self.uartConnected)
        bus.uart_disconnected.connect(self.uartDisconnected)
        bus.webcam_ready.connect(self.webcamReady)
        bus.webcam_error.connect(self.webcamError)
        bus.frame_captured.connect(self.frameCaptured)
        bus.frame_undone.connect(self.frameUndone)
        bus.frame_deleted.connect(self.frameDeleted)
        bus.session_reset.connect(self.sessionReset)
        bus.export_started.connect(self.exportStarted)
        bus.export_progress.connect(self.exportProgress)
        bus.export_completed.connect(self._on_export_completed)
        bus.export_failed.connect(self.exportFailed)
        bus.status_message.connect(self.statusMessage)

    def _on_export_completed(self, payload: dict) -> None:
        self.exportCompleted.emit(
            payload.get("mp4_path", ""),
            payload.get("gif_path", ""),
            payload.get("share_url", ""),
            payload.get("qr_path", ""),
        )


def _resolve_ffmpeg(configured: str) -> str:
    """Find ffmpeg binary — prefer configured value, else search PATH and Homebrew."""
    if Path(configured).exists():
        return configured
    found = shutil.which(configured)
    if found:
        return found
    for candidate in ("/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"):
        if Path(candidate).exists():
            return candidate
    return configured  # let it fail later with a clear ffmpeg error


def _open_capture(settings: AppSettings) -> CaptureEngine:
    """Open configured webcam, then probe nearby indexes before giving up."""
    configured_index = settings.capture.webcam_index
    indexes = [configured_index] + [i for i in range(6) if i != configured_index]
    explicit_index = "NEO_STOPMOTION_WEBCAM_INDEX" in os.environ
    last_error: CaptureError | None = None

    for pos, index in enumerate(indexes):
        retry_count = settings.capture.auto_retry_count if pos == 0 else 1
        capture = CaptureEngine(
            webcam_index=index,
            resolution=(settings.capture.resolution_width, settings.capture.resolution_height),
            onion_opacity=settings.capture.onion_opacity,
            retry_count=retry_count,
        )
        try:
            capture.open()
            if index != configured_index:
                logger.info(f"Using detected webcam index {index} instead of {configured_index}")
            return capture
        except CaptureError as e:
            last_error = e
            if explicit_index:
                break
            logger.warning(f"Webcam index {index} unavailable: {e}")

    raise CaptureError("No usable webcam found") from last_error


def run() -> int:
    settings = load_settings()
    log_dir = Path.home() / ".local" / "share" / "neostopmotion" / "logs"
    configure_logging(log_dir=log_dir, debug=settings.app.debug)
    logger.info(f"Starting NeoStopMotion v{settings.app.version}")

    app = QGuiApplication(sys.argv)
    app.setApplicationName("NeoStopMotion")
    app.setOrganizationName("MakerViet")

    bus = SignalBus.instance()

    use_synthetic = os.environ.get("NEO_STOPMOTION_CAPTURE", "").lower() == "synthetic"
    if use_synthetic:
        capture = SyntheticCaptureEngine(
            resolution=(settings.capture.resolution_width, settings.capture.resolution_height),
            onion_opacity=settings.capture.onion_opacity,
        )
        capture.open()
        bus.webcam_ready.emit()
    else:
        try:
            capture = _open_capture(settings)
            bus.webcam_ready.emit()
        except CaptureError as e:
            logger.warning(f"Webcam unavailable ({e}); falling back to SyntheticCaptureEngine")
            capture = SyntheticCaptureEngine(
                resolution=(settings.capture.resolution_width, settings.capture.resolution_height),
                onion_opacity=settings.capture.onion_opacity,
            )
            capture.open()
            bus.webcam_ready.emit()

    # Resolve writable projects directory. Spec default /home/maker/projects (NEO One
    # Linux); on macOS dev fall back to ~/neostopmotion_sessions/.
    projects_dir = Path(settings.storage.projects_dir).expanduser()
    if not projects_dir.exists():
        try:
            projects_dir.mkdir(parents=True, exist_ok=True)
        except (PermissionError, OSError):
            projects_dir = Path.home() / "neostopmotion_sessions"
            projects_dir.mkdir(parents=True, exist_ok=True)
            logger.warning(f"Falling back to {projects_dir} (default not writable)")
    session = SessionService(
        projects_dir=projects_dir,
        fps_playback=settings.export.playback_fps,
    )

    ffmpeg_bin = _resolve_ffmpeg(settings.export.ffmpeg_binary)
    watermark = Path(__file__).parent / "resources" / "images" / "maker_viet_logo.png"
    exporter = VideoExporter(
        fps=settings.export.playback_fps,
        ffmpeg=ffmpeg_bin,
        codec=settings.export.mp4_codec,
        pix_fmt=settings.export.mp4_pix_fmt,
        gif_scale_width=settings.export.gif_scale_width,
        watermark_path=watermark if watermark.exists() else None,
    )
    cloud_enabled = os.environ.get("NEO_STOPMOTION_CLOUD", "1").lower() not in ("0", "false", "no", "off")
    uploader = CloudUploader() if cloud_enabled else None
    export_service = ExportService(exporter, uploader)
    logger.info(f"Using ffmpeg: {ffmpeg_bin}")
    logger.info(f"Cloud share: {'enabled (catbox.moe)' if cloud_enabled else 'disabled'}")

    controller = AppController(
        capture=capture,
        session=session,
        export_service=export_service,
        min_frames=settings.export.min_frames,
    )

    uart_mode = settings.uart.port
    if uart_mode == "simulator":
        uart = UARTSimulator()
        uart.start()
        logger.info("UART: simulator mode (keyboard only)")
    else:
        uart = UARTListener(
            port=None if uart_mode == "auto" else uart_mode,
            baudrate=settings.uart.baudrate,
            reconnect_interval_seconds=settings.uart.reconnect_interval_seconds,
        )
        uart.start()
        logger.info(f"UART: hardware listener (port={uart.port or 'searching...'})")
    app.aboutToQuit.connect(uart.stop)

    bridge = _SignalBusBridge(bus)

    resources_dir = Path(__file__).parent / "resources"
    resources_url = QUrl.fromLocalFile(str(resources_dir)).toString()

    engine = QQmlApplicationEngine()
    engine.addImageProvider("preview", PreviewImageProvider(capture))
    engine.addImportPath(str(find_qml_root()))
    engine.rootContext().setContextProperty("appController", controller)
    engine.rootContext().setContextProperty("signalBusBridge", bridge)
    engine.rootContext().setContextProperty("resourcesUrl", resources_url)
    engine.load(QUrl.fromLocalFile(str(main_qml_path())))

    if not engine.rootObjects():
        logger.error("Failed to load QML")
        return 1

    # Auto-test mode: fires N SHOOT commands then EXPORT then waits 12s and quits.
    autoshoot = int(os.environ.get("NEO_STOPMOTION_AUTOSHOOT", "0"))
    auto_export = os.environ.get("NEO_STOPMOTION_AUTOEXPORT", "").lower() in ("1", "true", "yes")
    if autoshoot > 0:
        logger.info(
            f"AUTOSHOOT mode: will fire {autoshoot} SHOOT"
            + (" then EXPORT" if auto_export else "")
        )
        state = {"remaining": autoshoot, "exported": False}

        def _tick() -> None:
            if state["remaining"] > 0:
                controller.handle_uart_command("SHOOT")
                state["remaining"] -= 1
                return
            if auto_export and not state["exported"]:
                state["exported"] = True
                logger.info(f"AUTOSHOOT done ({autoshoot} frames). Triggering EXPORT...")
                controller.handle_uart_command("EXPORT")
                QTimer.singleShot(20000, app.quit)
            elif not auto_export:
                logger.info(f"AUTOSHOOT done. Final frame count: {controller.frameCount}")
                app.quit()

        autoshoot_timer = QTimer()
        autoshoot_timer.setInterval(600)
        autoshoot_timer.timeout.connect(_tick)
        QTimer.singleShot(2500, autoshoot_timer.start)

    code = app.exec()
    capture.release()
    return code
