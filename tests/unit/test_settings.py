from pathlib import Path
from neo_stopmotion.config.settings import load_settings, AppSettings


def test_load_defaults():
    s = load_settings()
    assert isinstance(s, AppSettings)
    assert s.app.name == "NeoStopMotion"
    assert s.capture.resolution_width == 1280
    assert s.uart.baudrate == 115200
    assert s.export.playback_fps == 10


def test_load_with_user_override(tmp_path):
    user = tmp_path / "config.toml"
    user.write_text('[capture]\nwebcam_index = 1\n')
    s = load_settings(user_config_path=user)
    assert s.capture.webcam_index == 1
    assert s.capture.resolution_width == 1280  # default kept


def test_env_override(monkeypatch):
    monkeypatch.setenv("NEO_STOPMOTION_UART_PORT", "/dev/ttyACM0")
    s = load_settings()
    assert s.uart.port == "/dev/ttyACM0"
