import sys
from PyQt6.QtCore import QUrl
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine

from neo_stopmotion.ui.qml_loader import main_qml_path


def run() -> int:
    """Application entry — launch the QML UI."""
    app = QGuiApplication(sys.argv)
    app.setApplicationName("NeoStopMotion")
    app.setOrganizationName("MakerViet")

    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(main_qml_path())))

    if not engine.rootObjects():
        print("Failed to load QML", file=sys.stderr)
        return 1

    return app.exec()
