"""Tests for AppController.handle_delete_frame() + signal frame_deleted — T-003 AC2/AC3.

TS-09: frame_deleted signal emitted with correct new_count value.
"""

from __future__ import annotations

from unittest.mock import MagicMock

import numpy as np
import pytest
from neo_stopmotion.services.app_controller import AppController
from neo_stopmotion.utils.signal_bus import SignalBus

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def mock_capture() -> MagicMock:
    cap = MagicMock()
    cap.capture_frame.return_value = np.full((480, 640, 3), 128, dtype=np.uint8)
    return cap


@pytest.fixture
def real_session(tmp_path):  # type: ignore[no-untyped-def]
    from neo_stopmotion.services.session_service import SessionService

    return SessionService(projects_dir=tmp_path, fps_playback=10)


def _shoot_n(ctrl: AppController, n: int) -> None:
    for _ in range(n):
        ctrl.handle_uart_command("SHOOT")


# ---------------------------------------------------------------------------
# TS-09 extension — frame_deleted signal emitted with correct value
# ---------------------------------------------------------------------------


def test_ts09_frame_deleted_signal_value(
    mock_capture: MagicMock, real_session: object
) -> None:
    """TS-09: handle_delete_frame(n) emits frame_deleted(new_count) correctly."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    bus = SignalBus.instance()

    received: list[int] = []
    bus.frame_deleted.connect(lambda count: received.append(count))

    _shoot_n(ctrl, 3)
    ctrl.handle_delete_frame(2)  # delete frame 2 from 3 → new_count=2

    assert received == [2], f"Expected [2], got {received}"
    assert ctrl.frameCount == 2


def test_handle_delete_frame_invalid_raises_status_message(
    mock_capture: MagicMock, real_session: object
) -> None:
    """handle_delete_frame with invalid n → status_message warning, no crash."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    bus = SignalBus.instance()

    warnings: list[tuple[str, str]] = []
    bus.status_message.connect(lambda lvl, msg: warnings.append((lvl, msg)))

    # No frames yet — delete(1) should emit warning, not raise
    ctrl.handle_delete_frame(1)

    assert len(warnings) == 1
    assert warnings[0][0] == "warning"


def test_handle_delete_frame_updates_frame_count_property(
    mock_capture: MagicMock, real_session: object
) -> None:
    """AppController.frameCount decreases after handle_delete_frame."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    _shoot_n(ctrl, 5)
    assert ctrl.frameCount == 5
    ctrl.handle_delete_frame(3)
    assert ctrl.frameCount == 4


def test_handle_delete_frame_does_not_touch_uart_contract(
    mock_capture: MagicMock, real_session: object
) -> None:
    """UNDO via UART still uses undo_last_frame, not delete_frame."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    bus = SignalBus.instance()

    frame_deleted_count: list[int] = []
    frame_undone_count: list[int] = []
    bus.frame_deleted.connect(lambda c: frame_deleted_count.append(c))
    bus.frame_undone.connect(lambda c: frame_undone_count.append(c))

    _shoot_n(ctrl, 3)
    ctrl.handle_uart_command("UNDO")

    # UART UNDO should emit frame_undone, NOT frame_deleted
    assert frame_undone_count == [2]
    assert frame_deleted_count == []
