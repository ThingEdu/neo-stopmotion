from unittest.mock import MagicMock
import numpy as np
import pytest
from neo_stopmotion.services.app_controller import AppController
from neo_stopmotion.utils.signal_bus import SignalBus


@pytest.fixture
def mock_capture():
    cap = MagicMock()
    cap.capture_frame.return_value = np.full((720, 1280, 3), 100, dtype=np.uint8)
    return cap


@pytest.fixture
def mock_session(tmp_path):
    from neo_stopmotion.services.session_service import SessionService
    return SessionService(projects_dir=tmp_path, fps_playback=10)


def test_handle_shoot_captures_and_saves(mock_capture, mock_session):
    ctrl = AppController(capture=mock_capture, session=mock_session)
    bus = SignalBus.instance()
    received = []
    bus.frame_captured.connect(lambda n, p: received.append(n))
    ctrl.handle_uart_command("SHOOT")
    assert mock_capture.capture_frame.called
    assert mock_session.frame_manager.frame_count == 1
    assert received == [1]


def test_handle_undo_removes_frame(mock_capture, mock_session):
    ctrl = AppController(capture=mock_capture, session=mock_session)
    ctrl.handle_uart_command("SHOOT")
    ctrl.handle_uart_command("SHOOT")
    assert mock_session.frame_manager.frame_count == 2
    ctrl.handle_uart_command("UNDO")
    assert mock_session.frame_manager.frame_count == 1


def test_undo_when_empty_is_silent(mock_capture, mock_session):
    ctrl = AppController(capture=mock_capture, session=mock_session)
    ctrl.handle_uart_command("UNDO")
    assert mock_session.frame_manager.frame_count == 0


def test_unknown_command_logged(mock_capture, mock_session):
    ctrl = AppController(capture=mock_capture, session=mock_session)
    ctrl.handle_uart_command("XYZ")  # should not raise
