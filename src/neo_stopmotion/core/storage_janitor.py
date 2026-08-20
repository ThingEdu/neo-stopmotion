"""Keep the sessions folder inside a size budget by evicting the oldest films.

Frames are stored as full-resolution PNGs, so a single busy session can run to
well over 100 MB. Nothing used to clean them up, which on a NEO One's SD card
ends as a full disk — and a full disk shows up as capture failing mid-film,
which is the worst possible moment for a child.

Policy: oldest film goes first, and the session currently being filmed is never
touched even when it alone busts the budget.
"""
from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path

from loguru import logger

SESSION_PREFIX = "session_"


@dataclass(frozen=True)
class SessionEntry:
    path: Path
    size_bytes: int
    sort_key: str


def directory_size(path: Path) -> int:
    """Bytes used by a directory tree. Files that vanish mid-walk are skipped."""
    total = 0
    for item in Path(path).rglob("*"):
        try:
            if item.is_file() and not item.is_symlink():
                total += item.stat().st_size
        except OSError:  # deleted underneath us, or unreadable
            continue
    return total


def list_sessions(projects_dir: Path) -> list[SessionEntry]:
    """Session directories, oldest first.

    Ordered by the timestamp baked into the directory name (`session_%Y_%m_%d_%H%M%S`),
    which is stable across copies and backups — unlike mtime, which any tool that
    touches the folder can rewrite.
    """
    root = Path(projects_dir)
    if not root.is_dir():
        return []
    entries = [
        SessionEntry(path=d, size_bytes=directory_size(d), sort_key=d.name)
        for d in root.iterdir()
        if d.is_dir() and d.name.startswith(SESSION_PREFIX)
    ]
    return sorted(entries, key=lambda e: e.sort_key)


def plan_eviction(
    sessions: list[SessionEntry],
    *,
    max_total_bytes: int,
    max_sessions: int,
    protect: Path | None = None,
) -> list[Path]:
    """Which sessions to delete, oldest first, to satisfy both caps.

    Pure — no filesystem writes — so the policy can be tested on its own.
    """
    protected = Path(protect).resolve() if protect is not None else None
    survivors = list(sessions)
    doomed: list[Path] = []

    def over_budget() -> bool:
        return (
            sum(e.size_bytes for e in survivors) > max_total_bytes
            or len(survivors) > max_sessions
        )

    while over_budget():
        victim = next(
            (e for e in survivors if protected is None or e.path.resolve() != protected),
            None,
        )
        if victim is None:
            break  # only the protected session is left; nothing more we may drop
        survivors.remove(victim)
        doomed.append(victim.path)
    return doomed


def enforce_quota(
    projects_dir: Path,
    *,
    max_total_mb: float,
    max_sessions: int,
    protect: Path | None = None,
) -> list[Path]:
    """Delete the oldest sessions until the folder fits the budget.

    Returns the sessions actually removed. A session that refuses to delete is
    logged and skipped — one stuck directory must not abort the whole cleanup.
    """
    sessions = list_sessions(projects_dir)
    if not sessions:
        return []

    doomed = plan_eviction(
        sessions,
        max_total_bytes=int(max_total_mb * 1024 * 1024),
        max_sessions=max_sessions,
        protect=protect,
    )
    removed: list[Path] = []
    for path in doomed:
        try:
            shutil.rmtree(path)
        except OSError as e:
            logger.warning(f"Không xoá được phim cũ {path.name}: {e}")
            continue
        removed.append(path)

    if removed:
        total_mb = sum(e.size_bytes for e in sessions) / 1024 / 1024
        logger.info(
            f"Dọn kho phim: xoá {len(removed)} phim cũ nhất "
            f"({', '.join(p.name for p in removed)}) — "
            f"trước dọn {total_mb:.0f} MB, hạn mức {max_total_mb:.0f} MB / {max_sessions} phim"
        )
    return removed
