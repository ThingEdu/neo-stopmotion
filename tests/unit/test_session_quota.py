"""SessionService must keep the sessions folder inside its budget as films pile up."""
from pathlib import Path

import pytest
from neo_stopmotion.services.session_service import SessionService


def _fill(session_dir: Path, size_kb: int) -> None:
    (session_dir / "frames").mkdir(parents=True, exist_ok=True)
    (session_dir / "frames" / "frame_0001.png").write_bytes(b"\0" * (size_kb * 1024))


@pytest.fixture
def projects_dir(tmp_path):
    return tmp_path / "sessions"


def test_old_sessions_are_evicted_when_starting_a_new_film(projects_dir):
    svc = SessionService(projects_dir=projects_dir, max_total_mb=0.2, max_sessions=50)
    first = svc.frame_manager.session_dir
    _fill(first, 150)
    # Marker, not the directory path: session ids are second-resolution, so a new
    # session started in the same second can legitimately reuse the freed name.
    (first / "marker.txt").write_text("phim dau tien")

    svc.reset()
    second = svc.frame_manager.session_dir
    _fill(second, 150)

    svc.reset()

    assert not (first / "marker.txt").exists(), "phim cũ nhất phải bị xoá khi vượt hạn mức"
    assert second.exists()
    assert svc.frame_manager.session_dir.exists()


def test_the_session_being_filmed_is_never_evicted(projects_dir):
    """Even a single film larger than the whole budget must survive while in use."""
    svc = SessionService(projects_dir=projects_dir, max_total_mb=0.01, max_sessions=1)
    current = svc.frame_manager.session_dir
    _fill(current, 500)

    svc.enforce_storage_quota()

    assert current.exists()


def test_nothing_is_deleted_while_within_budget(projects_dir):
    svc = SessionService(projects_dir=projects_dir, max_total_mb=100, max_sessions=50)
    first = svc.frame_manager.session_dir
    _fill(first, 10)

    svc.reset()

    assert first.exists()


def test_quota_disabled_when_max_total_mb_is_zero(projects_dir):
    """0 = tắt hạn mức, không phải 'xoá sạch'."""
    svc = SessionService(projects_dir=projects_dir, max_total_mb=0, max_sessions=0)
    first = svc.frame_manager.session_dir
    _fill(first, 50)

    svc.reset()

    assert first.exists()
