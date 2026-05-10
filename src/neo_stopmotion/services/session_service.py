from __future__ import annotations
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSlot
from loguru import logger

from neo_stopmotion.core.frame_manager import FrameManager


class SessionService(QObject):
    def __init__(self, projects_dir: Path, fps_playback: int = 10) -> None:
        super().__init__()
        self._projects_dir = projects_dir
        self._fps_playback = fps_playback
        self.frame_manager = FrameManager(projects_dir, fps_playback)

    @pyqtSlot()
    def reset(self) -> None:
        """Start a new session."""
        logger.info("Session reset")
        self.frame_manager = FrameManager(self._projects_dir, self._fps_playback)
