import sys
from pathlib import Path
from PyQt6.QtCore import QUrl
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine
from loguru import logger

from neo_stopmotion.config.settings import load_settings
from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError
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
        logger.error(f"Webcam init failed: {e}")
        bus.webcam_error.emit(str(e))

    engine = QQmlApplicationEngine()
    engine.addImageProvider("preview", PreviewImageProvider(capture))
    engine.addImportPath(str(find_qml_root()))
    engine.load(QUrl.fromLocalFile(str(main_qml_path())))

    if not engine.rootObjects():
        logger.error("Failed to load QML")
        return 1

    code = app.exec()
    capture.release()
    return code
