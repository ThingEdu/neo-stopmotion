import numpy as np
import pytest
from pathlib import Path
from neo_stopmotion.core.frame_manager import FrameManager


@pytest.fixture
def fm(tmp_path):
    return FrameManager(projects_dir=tmp_path)


@pytest.fixture
def frame():
    return np.full((720, 1280, 3), 100, dtype=np.uint8)


def test_create_session(fm):
    assert fm.frame_count == 0
    assert fm.session_dir.exists()
    assert (fm.session_dir / "frames").exists()
    assert (fm.session_dir / "project.json").exists()


def test_add_frame_writes_png(fm, frame):
    path = fm.add_frame(frame)
    assert path.exists()
    assert path.name == "frame_0001.png"
    assert fm.frame_count == 1
    meta = fm.metadata
    assert meta.frame_count == 1
    assert meta.duration_seconds == pytest.approx(0.1)


def test_add_multiple_frames(fm, frame):
    fm.add_frame(frame)
    fm.add_frame(frame)
    fm.add_frame(frame)
    assert fm.frame_count == 3
    assert (fm.session_dir / "frames" / "frame_0003.png").exists()


def test_undo_last_frame(fm, frame):
    fm.add_frame(frame)
    fm.add_frame(frame)
    ok = fm.undo_last_frame()
    assert ok is True
    assert fm.frame_count == 1
    assert not (fm.session_dir / "frames" / "frame_0002.png").exists()


def test_undo_when_empty(fm):
    assert fm.undo_last_frame() is False


def test_get_all_frames_sorted(fm, frame):
    for _ in range(3):
        fm.add_frame(frame)
    frames = fm.get_all_frames()
    assert [f.name for f in frames] == ["frame_0001.png", "frame_0002.png", "frame_0003.png"]


def test_set_title_persists(fm):
    fm.set_title("Robot bay vũ trụ", "Minh, 9 tuổi")
    assert fm.metadata.title == "Robot bay vũ trụ"
    assert fm.metadata.creator_name == "Minh, 9 tuổi"
    fm._save_metadata()
    import json
    data = json.loads((fm.session_dir / "project.json").read_text())
    assert data["title"] == "Robot bay vũ trụ"


def test_load_last_frame(fm, frame):
    fm.add_frame(frame)
    loaded = fm.load_frame(1)
    assert loaded is not None
    assert loaded.shape == frame.shape
