from __future__ import annotations

from pathlib import Path

from loguru import logger
from PyQt6.QtCore import QObject, pyqtSlot

from neo_stopmotion.core.frame_manager import FrameManager
from neo_stopmotion.core.storage_janitor import enforce_quota


class SessionService(QObject):
    def __init__(
        self,
        projects_dir: Path,
        fps_playback: int = 10,
        max_total_mb: float = 0,
        max_sessions: int = 0,
    ) -> None:
        """max_total_mb / max_sessions: 0 tắt hạn mức tương ứng."""
        super().__init__()
        self._projects_dir = projects_dir
        self._fps_playback = fps_playback
        self._max_total_mb = max_total_mb
        self._max_sessions = max_sessions
        self.frame_manager = FrameManager(projects_dir, fps_playback)

    def enforce_storage_quota(self) -> list[Path]:
        """Xoá các phim cũ nhất cho tới khi kho phim nằm trong hạn mức.

        Phiên đang quay luôn được giữ lại, kể cả khi một mình nó đã vượt hạn mức —
        thà đầy thẻ còn hơn xoá phim của đứa trẻ đang quay dở.
        """
        if self._max_total_mb <= 0 and self._max_sessions <= 0:
            return []
        return enforce_quota(
            self._projects_dir,
            # 0 = tắt: quy về "không giới hạn" thay vì "xoá sạch".
            max_total_mb=self._max_total_mb if self._max_total_mb > 0 else float("inf"),
            max_sessions=self._max_sessions if self._max_sessions > 0 else 10**9,
            protect=self.frame_manager.session_dir,
        )

    @pyqtSlot()
    def reset(self) -> None:
        """Start a new session."""
        logger.info("Session reset")
        # Dọn TRƯỚC khi mở phiên mới, để phiên mới có sẵn chỗ trống trên thẻ.
        self.enforce_storage_quota()
        self.frame_manager = FrameManager(self._projects_dir, self._fps_playback)
