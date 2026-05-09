from neo_stopmotion.ui.qml_loader import find_qml_root


def test_find_qml_root_returns_existing_path():
    path = find_qml_root()
    assert path.exists()
    assert (path / "MainWindow.qml").exists()
