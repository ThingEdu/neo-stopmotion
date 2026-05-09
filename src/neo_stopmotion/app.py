import sys
from pathlib import Path
from PyQt6.QtCore import QUrl
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine
from loguru import logger

from neo_stopmotion.config.settings import load_settings
from neo_stopmotion.ui.qml_loader import main_qml_path
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

    SignalBus.instance()  # init early

    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(main_qml_path())))

    if not engine.rootObjects():
        logger.error("Failed to load QML")
        return 1

    return app.exec()
