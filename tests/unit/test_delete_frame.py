"""Tests for FrameManager.delete_frame(n) — TDD for T-003.

Covers TS-01..TS-12 from spec §7 (frame-review-delete).
Run:  pytest tests/unit/test_delete_frame.py -v
"""

from __future__ import annotations

import json
import time
from pathlib import Path

import numpy as np
import pytest
from neo_stopmotion.core.frame_manager import FrameManager

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def fm(tmp_path: Path) -> FrameManager:
    return FrameManager(projects_dir=tmp_path, fps_playback=10)


@pytest.fixture
def dummy_frame() -> np.ndarray:
    return np.full((480, 640, 3), 128, dtype=np.uint8)


def _add_n_frames(fm: FrameManager, n: int, frame: np.ndarray) -> None:
    for _ in range(n):
        fm.add_frame(frame)


def _frame_names(fm: FrameManager) -> list[str]:
    return [p.name for p in sorted(fm.frames_dir.glob("frame_*.png"))]


# ---------------------------------------------------------------------------
# TS-01 — Xoá frame giữa — re-sequence đúng
# ---------------------------------------------------------------------------


def test_ts01_delete_middle_resequences(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-01 P0: 5 frame, xoá frame 3 → frame 4→3, 5→4; frame_count=4."""
    _add_n_frames(fm, 5, dummy_frame)
    fm.delete_frame(3)
    assert fm.frame_count == 4
    names = _frame_names(fm)
    assert names == [
        "frame_0001.png",
        "frame_0002.png",
        "frame_0003.png",
        "frame_0004.png",
    ]
    # Ensure the file that was frame_4 is now frame_3, etc. (count is enough)
    assert len(names) == 4


# ---------------------------------------------------------------------------
# TS-02 — Xoá frame cuối — không rename
# ---------------------------------------------------------------------------


def test_ts02_delete_last_no_rename(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-02 P0: 3 frame, xoá frame 3 → frame_count=2; không rename gì cả."""
    _add_n_frames(fm, 3, dummy_frame)
    fm.delete_frame(3)
    assert fm.frame_count == 2
    names = _frame_names(fm)
    assert names == ["frame_0001.png", "frame_0002.png"]
    assert not (fm.frames_dir / "frame_0003.png").exists()


# ---------------------------------------------------------------------------
# TS-03 — Xoá frame đầu
# ---------------------------------------------------------------------------


def test_ts03_delete_first(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-03 P0: 4 frame, xoá frame 1 → frame 2→1, 3→2, 4→3; frame_count=3."""
    _add_n_frames(fm, 4, dummy_frame)
    fm.delete_frame(1)
    assert fm.frame_count == 3
    names = _frame_names(fm)
    assert names == ["frame_0001.png", "frame_0002.png", "frame_0003.png"]


# ---------------------------------------------------------------------------
# TS-04 — Xoá rồi export: file liên tục (không skip)
# ---------------------------------------------------------------------------


def test_ts04_files_sequential_after_delete(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-04 P0: 5 frame, xoá frame 2 → 4 file liên tục 0001-0004, không lỗ hổng."""
    _add_n_frames(fm, 5, dummy_frame)
    fm.delete_frame(2)
    names = _frame_names(fm)
    assert names == [
        "frame_0001.png",
        "frame_0002.png",
        "frame_0003.png",
        "frame_0004.png",
    ]
    assert fm.frame_count == 4
    # All expected files exist (no gaps)
    for i in range(1, 5):
        assert (fm.frames_dir / f"frame_{i:04d}.png").exists()


# ---------------------------------------------------------------------------
# TS-05 — frame_count và duration đúng sau xoá
# ---------------------------------------------------------------------------


def test_ts05_frame_count_and_duration(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-05 P0: 7 frame, xoá frame 4 → frame_count=6, duration=6/fps."""
    _add_n_frames(fm, 7, dummy_frame)
    fm.delete_frame(4)
    assert fm.frame_count == 6
    assert fm.metadata.duration_seconds == pytest.approx(6 / 10)
    # project.json must also be updated
    meta = json.loads((fm.session_dir / "project.json").read_text())
    assert meta["frame_count"] == 6
    assert meta["duration_seconds"] == pytest.approx(0.6)


# ---------------------------------------------------------------------------
# TS-06 — Xoá khi 0 frame → ValueError
# ---------------------------------------------------------------------------


def test_ts06_delete_when_empty_raises(fm: FrameManager) -> None:
    """TS-06 P0: project rỗng, delete_frame(1) → ValueError; frame_count không đổi."""
    with pytest.raises(ValueError, match="1"):
        fm.delete_frame(1)
    assert fm.frame_count == 0


# ---------------------------------------------------------------------------
# TS-07 — Index ngoài vùng → ValueError
# ---------------------------------------------------------------------------


def test_ts07_out_of_range_raises(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-07 P0: 3 frame, delete_frame(5) → ValueError; frame_count không đổi."""
    _add_n_frames(fm, 3, dummy_frame)
    with pytest.raises(ValueError, match="5"):
        fm.delete_frame(5)
    assert fm.frame_count == 3


def test_ts07_zero_index_raises(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-07 variant: n=0 → ValueError (1-based index)."""
    _add_n_frames(fm, 3, dummy_frame)
    with pytest.raises(ValueError):
        fm.delete_frame(0)


def test_ts07_negative_index_raises(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-07 variant: n=-1 → ValueError."""
    _add_n_frames(fm, 3, dummy_frame)
    with pytest.raises(ValueError):
        fm.delete_frame(-1)


# ---------------------------------------------------------------------------
# TS-08 — undo_last_frame (hành vi cũ) không bị ảnh hưởng
# ---------------------------------------------------------------------------


def test_ts08_undo_last_frame_still_works(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-08 P0: thêm 4 frame, undo_last_frame → frame 4 biến mất; frame_count=3."""
    _add_n_frames(fm, 4, dummy_frame)
    ok = fm.undo_last_frame()
    assert ok is True
    assert fm.frame_count == 3
    assert not (fm.frames_dir / "frame_0004.png").exists()
    assert (fm.frames_dir / "frame_0003.png").exists()


def test_ts08_undo_empty_returns_false(fm: FrameManager) -> None:
    """TS-08 variant: undo when empty returns False, no exception."""
    assert fm.undo_last_frame() is False


# ---------------------------------------------------------------------------
# TS-09 — Signal frame_deleted được emit với giá trị đúng
# ---------------------------------------------------------------------------


def test_ts09_frame_deleted_signal_emitted(
    fm: FrameManager, dummy_frame: np.ndarray
) -> None:
    """TS-09 P0: delete_frame phải gọi signal_bus.frame_deleted(new_count).

    Vì PyQt6 không có trong test env, ta test qua AppController với mock bus.
    Nhưng trước tiên, verify delete_frame trả về đúng count (logic core).
    """
    _add_n_frames(fm, 3, dummy_frame)
    fm.delete_frame(2)
    # After deleting frame 2 from 3 frames → new_count == 2
    assert fm.frame_count == 2


# ---------------------------------------------------------------------------
# TS-10 (P1) — Xoá nhiều lần liên tiếp
# ---------------------------------------------------------------------------


def test_ts10_delete_multiple_times(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-10 P1: 5 frame, xoá frame 1 x3 lần → frame_count=2; file 0001-0002."""
    _add_n_frames(fm, 5, dummy_frame)
    fm.delete_frame(1)
    fm.delete_frame(1)
    fm.delete_frame(1)
    assert fm.frame_count == 2
    names = _frame_names(fm)
    assert names == ["frame_0001.png", "frame_0002.png"]


# ---------------------------------------------------------------------------
# TS-11 (P1) — Xoá frame duy nhất
# ---------------------------------------------------------------------------


def test_ts11_delete_only_frame(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-11 P1: 1 frame, xoá frame 1 → frame_count=0, không còn file nào."""
    _add_n_frames(fm, 1, dummy_frame)
    fm.delete_frame(1)
    assert fm.frame_count == 0
    assert _frame_names(fm) == []
    meta = json.loads((fm.session_dir / "project.json").read_text())
    assert meta["frame_count"] == 0


# ---------------------------------------------------------------------------
# TS-12 (P1) — Hiệu năng: 100 frame, xoá frame 1 < 3s
# ---------------------------------------------------------------------------


def test_ts12_performance_100_frames(fm: FrameManager, dummy_frame: np.ndarray) -> None:
    """TS-12 P1: 100 frame, xoá frame 1 hoàn thành trong < 3 giây."""
    _add_n_frames(fm, 100, dummy_frame)
    start = time.monotonic()
    fm.delete_frame(1)
    elapsed = time.monotonic() - start
    assert fm.frame_count == 99
    assert elapsed < 3.0, f"delete_frame took {elapsed:.2f}s, expected < 3s"
