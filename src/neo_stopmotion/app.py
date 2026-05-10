import os
import sys
from pathlib import Path
from PyQt6.QtCore import QTimer, QUrl
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine
from loguru import logger

from neo_stopmotion.config.settings import load_settings
from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError
from neo_stopmotion.core.synthetic_capture import SyntheticCaptureEngine
from neo_stopmotion.services.app_controller import AppController
from neo_stopmotion.services.session_service import SessionService
from neo_stopmotion.ui.image_provider import PreviewImageProvider
from neo_stopmotion.ui.qml_loader import find_qml_root, main_qml_path
from neo_stopmotion.utils.logging_config import configure_logging
from neo_stopmotion.utils.signal_bus import SignalBus


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
        capture = CaptureEngine(
            webcam_index=settings.capture.webcam_index,
            resolution=(settings.capture.resolution_width, settings.capture.resolution_height),
            onion_opacity=settings.capture.onion_opacity,
            retry_count=settings.capture.auto_retry_count,
        )
        try:
            capture.open()
            bus.webcam_ready.emit()
        except CaptureError as e:
            logger.warning(f"Webcam unavailable ({e}); falling back to SyntheticCaptureEngine")
            capture = SyntheticCaptureEngine(
                resolution=(settings.capture.resolution_width, settings.capture.resolution_height),
                onion_opacity=settings.capture.onion_opacity,
            )
            capture.open()
            bus.webcam_ready.emit()

    # Resolve a writable projects directory. Spec default is /home/maker/projects
    # (NEO One Linux). On macOS dev that path isn't writable, so fall back to
    # ~/neostopmotion_sessions/.
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
    controller = AppController(capture=capture, session=session)

    engine = QQmlApplicationEngine()
    engine.addImageProvider("preview", PreviewImageProvider(capture))
    engine.addImportPath(str(find_qml_root()))
    engine.rootContext().setContextProperty("appController", controller)
    engine.load(QUrl.fromLocalFile(str(main_qml_path())))

    if not engine.rootObjects():
        logger.error("Failed to load QML")
        return 1

    # Auto-test mode: fires SHOOT commands every 600ms then quits.
    # Useful for headless verification on systems without keyboard focus / camera.
    autoshoot = int(os.environ.get("NEO_STOPMOTION_AUTOSHOOT", "0"))
    if autoshoot > 0:
        logger.info(f"AUTOSHOOT mode: will fire {autoshoot} SHOOT then quit")
        state = {"remaining": autoshoot}

        def _tick() -> None:
            if state["remaining"] <= 0:
                logger.info(f"AUTOSHOOT done. Final frame count: {controller.frameCount}")
                app.quit()
                return
            controller.handle_uart_command("SHOOT")
            state["remaining"] -= 1

        QTimer.singleShot(2500, _tick)  # first shot after splash + 500ms
        autoshoot_timer = QTimer()
        autoshoot_timer.setInterval(600)
        autoshoot_timer.timeout.connect(_tick)
        QTimer.singleShot(2500, autoshoot_timer.start)

    code = app.exec()
    capture.release()
    return code
