"""EXPORT must end the film exactly once.

Bug reproduced on NEO One 2026-08-19: on SuccessPage, pressing Enter (or the red
ThingBot button) fired EXPORT again and re-rendered the same frames into a new
film — so "kết thúc làm phim" never actually ended anything. Pressing it twice
while the first export was still running started two ffmpeg pipelines at once.
"""
from unittest.mock import MagicMock

import numpy as np
import pytest
from neo_stopmotion.services.app_controller import AppController
from neo_stopmotion.services.session_service import SessionService


@pytest.fixture
def mock_capture():
    cap = MagicMock()
    cap.capture_frame.return_value = np.full((720, 1280, 3), 100, dtype=np.uint8)
    return cap


@pytest.fixture
def mock_session(tmp_path):
    return SessionService(projects_dir=tmp_path, fps_playback=10)


def _controller_with_frames(capture, session, export_service, n=5):
    ctrl = AppController(capture=capture, session=session, export_service=export_service)
    for _ in range(n):
        ctrl.handle_uart_command("SHOOT")
    return ctrl


def test_export_starts_once_when_pressed_twice_in_a_row(mock_capture, mock_session):
    export = MagicMock()
    ctrl = _controller_with_frames(mock_capture, mock_session, export)

    ctrl.handle_uart_command("EXPORT")
    ctrl.handle_uart_command("EXPORT")

    assert export.start_export.call_count == 1


def test_export_ignored_after_film_is_finished(mock_capture, mock_session):
    export = MagicMock()
    ctrl = _controller_with_frames(mock_capture, mock_session, export)

    ctrl.handle_uart_command("EXPORT")
    ctrl._on_export_completed({})  # film done, we are on SuccessPage
    ctrl.handle_uart_command("EXPORT")

    assert export.start_export.call_count == 1


def test_export_works_again_after_starting_a_new_film(mock_capture, mock_session):
    export = MagicMock()
    ctrl = _controller_with_frames(mock_capture, mock_session, export)

    ctrl.handle_uart_command("EXPORT")
    ctrl._on_export_completed({})
    ctrl.reset_session()
    for _ in range(5):
        ctrl.handle_uart_command("SHOOT")
    ctrl.handle_uart_command("EXPORT")

    assert export.start_export.call_count == 2


def test_failed_export_can_be_retried(mock_capture, mock_session):
    """A failed export must not lock the child out of ever finishing the film."""
    export = MagicMock()
    ctrl = _controller_with_frames(mock_capture, mock_session, export)

    ctrl.handle_uart_command("EXPORT")
    ctrl._on_export_failed("ffmpeg died")
    ctrl.handle_uart_command("EXPORT")

    assert export.start_export.call_count == 2


def test_too_few_frames_does_not_block_a_later_export(mock_capture, mock_session):
    export = MagicMock()
    ctrl = _controller_with_frames(mock_capture, mock_session, export, n=2)

    ctrl.handle_uart_command("EXPORT")  # rejected: needs 5 frames
    assert export.start_export.call_count == 0

    for _ in range(3):
        ctrl.handle_uart_command("SHOOT")
    ctrl.handle_uart_command("EXPORT")

    assert export.start_export.call_count == 1
