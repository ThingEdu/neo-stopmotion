"""Unit tests for T-011 keyboard shortcut logic.

TS-01: Del when selectedIndex > 0 → deletes that specific frame
TS-02: Del when selectedIndex = 0 (nothing selected) → deletes last frame
TS-03: select_speed("Cham"/"Vua"/"Nhanh") sets fps 5/8/12

Spec ref: docs/04-phases/phase-01-neo-device-polish/wave-4/T-011-keyboard-shortcuts.md
"""

from __future__ import annotations

from unittest.mock import MagicMock

import numpy as np
import pytest

from neo_stopmotion.services.app_controller import AppController  # noqa: E402
from neo_stopmotion.utils.signal_bus import SignalBus  # noqa: E402

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
# TS-01: Del when selectedIndex > 0 → deletes that specific frame
# ---------------------------------------------------------------------------


def test_ts01_delete_smart_with_selection_deletes_selected(
    mock_capture: MagicMock, real_session: object
) -> None:
    """TS-01 (P0): delete_frame_smart(n) with n>0 deletes that specific frame."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    bus = SignalBus.instance()

    deleted_counts: list[int] = []
    bus.frame_deleted.connect(lambda c: deleted_counts.append(c))

    _shoot_n(ctrl, 4)  # frames: 1, 2, 3, 4
    assert ctrl.frameCount == 4

    # Delete frame 2 while it is "selected"
    ctrl.delete_frame_smart(2)

    assert ctrl.frameCount == 3, f"Expected 3 frames remaining, got {ctrl.frameCount}"
    assert deleted_counts == [3], f"Expected frame_deleted signal with 3, got {deleted_counts}"


# ---------------------------------------------------------------------------
# TS-02: Del when selectedIndex = 0 → deletes last frame
# ---------------------------------------------------------------------------


def test_ts02_delete_smart_no_selection_deletes_last(
    mock_capture: MagicMock, real_session: object
) -> None:
    """TS-02 (P0): delete_frame_smart(0) with nothing selected deletes last frame."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    bus = SignalBus.instance()

    deleted_counts: list[int] = []
    bus.frame_deleted.connect(lambda c: deleted_counts.append(c))

    _shoot_n(ctrl, 5)  # frames: 1, 2, 3, 4, 5
    assert ctrl.frameCount == 5

    # selectedIndex=0 means nothing selected → delete last (frame 5)
    ctrl.delete_frame_smart(0)

    assert ctrl.frameCount == 4, f"Expected 4 frames remaining, got {ctrl.frameCount}"
    assert deleted_counts == [4], f"Expected frame_deleted signal with 4, got {deleted_counts}"


def test_ts02_delete_smart_no_frames_is_noop(
    mock_capture: MagicMock, real_session: object
) -> None:
    """TS-02 extension: delete_frame_smart when no frames exist is a no-op."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    bus = SignalBus.instance()

    deleted_counts: list[int] = []
    bus.frame_deleted.connect(lambda c: deleted_counts.append(c))

    ctrl.delete_frame_smart(0)  # no frames at all

    assert ctrl.frameCount == 0
    assert deleted_counts == [], "No frame_deleted signal expected when no frames"


def test_ts01_delete_smart_out_of_range_falls_back_to_last(
    mock_capture: MagicMock, real_session: object
) -> None:
    """delete_frame_smart with out-of-range selectedIndex falls back to last frame."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    bus = SignalBus.instance()

    deleted_counts: list[int] = []
    bus.frame_deleted.connect(lambda c: deleted_counts.append(c))

    _shoot_n(ctrl, 3)  # frames: 1, 2, 3
    # selectedIndex = 99 (stale / out-of-range) → should fall back to last
    ctrl.delete_frame_smart(99)

    # 99 > frame_count=3, so falls back to deleting last (frame 3)
    assert ctrl.frameCount == 2
    assert deleted_counts == [2]


# ---------------------------------------------------------------------------
# TS-03: select_speed sets correct fps
# ---------------------------------------------------------------------------


def test_ts03_select_speed_cham_sets_fps_5(
    mock_capture: MagicMock, real_session: object
) -> None:
    """TS-03 (P0): select_speed('Cham') → selected fps = 5."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    ctrl.select_speed("Cham")
    assert ctrl.get_selected_fps() == 5
    assert ctrl.get_selected_speed_label() == "Cham"


def test_ts03_select_speed_vua_sets_fps_8(
    mock_capture: MagicMock, real_session: object
) -> None:
    """TS-03 (P0): select_speed('Vua') → selected fps = 8."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    ctrl.select_speed("Vua")
    assert ctrl.get_selected_fps() == 8
    assert ctrl.get_selected_speed_label() == "Vua"


def test_ts03_select_speed_nhanh_sets_fps_12(
    mock_capture: MagicMock, real_session: object
) -> None:
    """TS-03 (P0): select_speed('Nhanh') → selected fps = 12."""
    ctrl = AppController(capture=mock_capture, session=real_session)
    ctrl.select_speed("Nhanh")
    assert ctrl.get_selected_fps() == 12
    assert ctrl.get_selected_speed_label() == "Nhanh"
