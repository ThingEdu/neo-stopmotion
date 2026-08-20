"""Keep the sessions folder inside a size budget by evicting the oldest films.

Motivated by the field: a NEO One with a 15 GB card had 35 sessions taking 346 MB,
one of them 162 MB on its own (frames are full-resolution PNGs). Nothing ever
cleaned them up — `max_sessions` and `auto_cleanup_threshold_mb` sat in
defaults.toml unimplemented — so the card fills up and capture starts failing.
"""
from pathlib import Path

import pytest
from neo_stopmotion.core.storage_janitor import (
    directory_size,
    enforce_quota,
    list_sessions,
    plan_eviction,
)


def _make_session(root: Path, name: str, size_kb: int) -> Path:
    d = root / name
    (d / "frames").mkdir(parents=True)
    (d / "frames" / "frame_0001.png").write_bytes(b"\0" * (size_kb * 1024))
    (d / "output.mp4").write_bytes(b"\0" * 1024)
    return d


@pytest.fixture
def projects_dir(tmp_path):
    return tmp_path / "sessions"


def test_directory_size_counts_nested_files(tmp_path):
    d = _make_session(tmp_path, "session_2026_01_01_000000", size_kb=10)
    assert directory_size(d) >= 10 * 1024


def test_list_sessions_returns_oldest_first(projects_dir):
    projects_dir.mkdir()
    _make_session(projects_dir, "session_2026_03_01_120000", 1)
    _make_session(projects_dir, "session_2026_01_01_120000", 1)
    _make_session(projects_dir, "session_2026_02_01_120000", 1)

    names = [s.path.name for s in list_sessions(projects_dir)]
    assert names == [
        "session_2026_01_01_120000",
        "session_2026_02_01_120000",
        "session_2026_03_01_120000",
    ]


def test_list_sessions_ignores_unrelated_entries(projects_dir):
    projects_dir.mkdir()
    _make_session(projects_dir, "session_2026_01_01_120000", 1)
    (projects_dir / "notes.txt").write_text("hello")
    (projects_dir / "random_dir").mkdir()

    assert [s.path.name for s in list_sessions(projects_dir)] == ["session_2026_01_01_120000"]


def test_list_sessions_on_missing_dir_is_empty(tmp_path):
    assert list_sessions(tmp_path / "nope") == []


def test_plan_eviction_drops_oldest_until_under_size_budget(projects_dir):
    projects_dir.mkdir()
    for n, kb in [("session_2026_01_01_120000", 100), ("session_2026_02_01_120000", 100),
                  ("session_2026_03_01_120000", 100)]:
        _make_session(projects_dir, n, kb)
    sessions = list_sessions(projects_dir)

    doomed = plan_eviction(sessions, max_total_bytes=250 * 1024, max_sessions=99, protect=None)

    assert [p.name for p in doomed] == ["session_2026_01_01_120000"]


def test_plan_eviction_honours_session_count_cap(projects_dir):
    projects_dir.mkdir()
    for i in range(1, 6):
        _make_session(projects_dir, f"session_2026_01_0{i}_120000", 1)
    sessions = list_sessions(projects_dir)

    doomed = plan_eviction(sessions, max_total_bytes=10**9, max_sessions=3, protect=None)

    assert [p.name for p in doomed] == ["session_2026_01_01_120000", "session_2026_01_02_120000"]


def test_plan_eviction_never_touches_the_protected_session(projects_dir):
    projects_dir.mkdir()
    oldest = _make_session(projects_dir, "session_2026_01_01_120000", 200)
    _make_session(projects_dir, "session_2026_02_01_120000", 200)
    sessions = list_sessions(projects_dir)

    doomed = plan_eviction(sessions, max_total_bytes=1024, max_sessions=1, protect=oldest)

    assert oldest not in doomed
    assert [p.name for p in doomed] == ["session_2026_02_01_120000"]


def test_plan_eviction_stops_when_only_protected_session_remains(projects_dir):
    """A single film bigger than the whole budget must not be deleted out from
    under the child who is filming it."""
    projects_dir.mkdir()
    only = _make_session(projects_dir, "session_2026_01_01_120000", 500)
    sessions = list_sessions(projects_dir)

    assert plan_eviction(sessions, max_total_bytes=1024, max_sessions=1, protect=only) == []


def test_enforce_quota_actually_removes_directories(projects_dir):
    projects_dir.mkdir()
    old = _make_session(projects_dir, "session_2026_01_01_120000", 100)
    keep = _make_session(projects_dir, "session_2026_02_01_120000", 100)

    removed = enforce_quota(projects_dir, max_total_mb=0.15, max_sessions=50)

    assert removed == [old]
    assert not old.exists()
    assert keep.exists()


def test_enforce_quota_is_a_noop_when_within_budget(projects_dir):
    projects_dir.mkdir()
    a = _make_session(projects_dir, "session_2026_01_01_120000", 10)

    assert enforce_quota(projects_dir, max_total_mb=100, max_sessions=50) == []
    assert a.exists()


def test_enforce_quota_survives_a_session_that_cannot_be_deleted(projects_dir, monkeypatch):
    """One unreadable/locked session must not stop the rest of the cleanup."""
    projects_dir.mkdir()
    stubborn = _make_session(projects_dir, "session_2026_01_01_120000", 100)
    second = _make_session(projects_dir, "session_2026_01_02_120000", 100)
    _make_session(projects_dir, "session_2026_01_03_120000", 100)

    import neo_stopmotion.core.storage_janitor as janitor

    real_rmtree = janitor.shutil.rmtree

    def flaky_rmtree(path, *args, **kwargs):
        if Path(path) == stubborn:
            raise PermissionError("locked")
        return real_rmtree(path, *args, **kwargs)

    monkeypatch.setattr(janitor.shutil, "rmtree", flaky_rmtree)

    removed = enforce_quota(projects_dir, max_total_mb=0.15, max_sessions=50)

    assert second in removed
    assert stubborn.exists()
    assert not second.exists()


def test_enforce_quota_on_missing_dir_does_nothing(tmp_path):
    assert enforce_quota(tmp_path / "nope", max_total_mb=1, max_sessions=1) == []


def test_two_films_started_in_the_same_second_get_separate_folders(tmp_path):
    """The session id is second-resolution; two films must still not share frames."""
    from neo_stopmotion.core.frame_manager import FrameManager

    a = FrameManager(tmp_path, fps_playback=10)
    b = FrameManager(tmp_path, fps_playback=10)

    assert a.session_dir != b.session_dir
    assert a.session_dir.exists() and b.session_dir.exists()
