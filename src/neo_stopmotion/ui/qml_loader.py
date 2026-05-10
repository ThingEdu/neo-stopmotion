from pathlib import Path


def find_qml_root() -> Path:
    """Return absolute path to the QML files directory."""
    return Path(__file__).parent / "qml"


def main_qml_path() -> Path:
    """Return absolute path to the MainWindow.qml entry."""
    return find_qml_root() / "MainWindow.qml"
