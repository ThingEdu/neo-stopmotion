from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path

import cv2
import numpy as np
from loguru import logger

from neo_stopmotion.core.models import SessionMeta


class FrameManager:
    """Persist frames as PNG + project.json metadata."""

    def __init__(self, projects_dir: Path, fps_playback: int = 10) -> None:
        self.projects_dir = Path(projects_dir)
        self.projects_dir.mkdir(parents=True, exist_ok=True)
        session_id = datetime.now().strftime("%Y_%m_%d_%H%M%S")
        self.session_dir = self.projects_dir / f"session_{session_id}"
        self.frames_dir = self.session_dir / "frames"
        self.frames_dir.mkdir(parents=True, exist_ok=True)
        self.metadata = SessionMeta(
            session_id=session_id,
            created_at=datetime.now(),
            fps_playback=fps_playback,
        )
        self._save_metadata()
        logger.info(f"Session created: {self.session_dir}")

    @property
    def frame_count(self) -> int:
        return self.metadata.frame_count

    def add_frame(self, frame: np.ndarray) -> Path:
        next_num = self.frame_count + 1
        filename = f"frame_{next_num:04d}.png"
        final_path = self.frames_dir / filename
        # Atomic write: encode -> tmp -> rename
        tmp_path = final_path.with_suffix(".png.tmp")
        ok, buf = cv2.imencode(".png", frame)
        if not ok:
            raise OSError(f"Failed to encode PNG for {final_path}")
        tmp_path.write_bytes(buf.tobytes())
        os.replace(tmp_path, final_path)
        self.metadata.frame_count = next_num
        self.metadata.duration_seconds = next_num / self.metadata.fps_playback
        self._save_metadata()
        logger.debug(f"Frame saved: {final_path}")
        return final_path

    def undo_last_frame(self) -> bool:
        if self.frame_count == 0:
            return False
        filename = f"frame_{self.frame_count:04d}.png"
        path = self.frames_dir / filename
        if not path.exists():
            return False
        path.unlink()
        self.metadata.frame_count -= 1
        self.metadata.duration_seconds = self.metadata.frame_count / self.metadata.fps_playback
        self._save_metadata()
        logger.info(f"Frame undone: {filename}")
        return True

    def delete_frame(self, n: int) -> None:
        """Delete frame at 1-based index n, re-sequence frames after it.

        Args:
            n: 1-based frame index to delete. Must be in [1, frame_count].

        Raises:
            ValueError: if n is out of range [1, frame_count].
        """
        if self.frame_count == 0 or n < 1 or n > self.frame_count:
            raise ValueError(
                f"Frame index {n} out of range [1, {self.frame_count}]"
            )

        target = self.frames_dir / f"frame_{n:04d}.png"
        target.unlink()
        logger.debug(f"Frame deleted: {target.name}")

        # Re-sequence: rename frame_(n+1)..frame_k → frame_n..frame_(k-1)
        # Iterate in ascending order to avoid overwriting existing files.
        if n < self.frame_count:
            for i in range(n + 1, self.frame_count + 1):
                src = self.frames_dir / f"frame_{i:04d}.png"
                dst = self.frames_dir / f"frame_{i - 1:04d}.png"
                src.rename(dst)
                logger.debug(f"Renamed {src.name} → {dst.name}")

        self.metadata.frame_count -= 1
        self.metadata.duration_seconds = (
            self.metadata.frame_count / self.metadata.fps_playback
        )
        self._save_metadata()
        logger.info(f"delete_frame({n}) done — new count: {self.metadata.frame_count}")

    def get_all_frames(self) -> list[Path]:
        return sorted(self.frames_dir.glob("frame_*.png"))

    def load_frame(self, frame_number: int) -> np.ndarray | None:
        path = self.frames_dir / f"frame_{frame_number:04d}.png"
        if not path.exists():
            return None
        img = cv2.imread(str(path))
        return img

    def set_title(self, title: str, creator_name: str = "") -> None:
        self.metadata.title = title
        self.metadata.creator_name = creator_name
        self._save_metadata()

    def _save_metadata(self) -> None:
        path = self.session_dir / "project.json"
        with path.open("w", encoding="utf-8") as f:
            json.dump(self.metadata.to_dict(), f, indent=2, ensure_ascii=False)
