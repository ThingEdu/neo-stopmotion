from __future__ import annotations
from dataclasses import dataclass, field, asdict
from datetime import datetime
from enum import Enum
from pathlib import Path


class UARTCommand(str, Enum):
    SHOOT = "SHOOT"
    UNDO = "UNDO"
    EXPORT = "EXPORT"
    READY = "READY"
    BAT_LOW = "BAT_LOW"


class SessionStatus(str, Enum):
    IDLE = "idle"
    CAPTURING = "capturing"
    EXPORTING = "exporting"
    COMPLETED = "completed"
    ERROR = "error"


@dataclass
class FrameInfo:
    frame_number: int
    filepath: Path
    captured_at: datetime
    width: int
    height: int


@dataclass
class SessionMeta:
    session_id: str
    created_at: datetime
    frame_count: int = 0
    fps_playback: int = 10
    duration_seconds: float = 0.0
    title: str = ""
    creator_name: str = ""
    status: SessionStatus = SessionStatus.IDLE
    exported: bool = False
    mp4_path: Path | None = None
    gif_path: Path | None = None
    qr_path: Path | None = None
    download_url: str | None = None

    def to_dict(self) -> dict:
        d = asdict(self)
        d["created_at"] = self.created_at.isoformat()
        d["status"] = self.status.value
        for k in ("mp4_path", "gif_path", "qr_path"):
            if d[k] is not None:
                d[k] = str(d[k])
        return d


@dataclass
class ExportResult:
    success: bool
    mp4_path: Path | None
    gif_path: Path | None
    qr_path: Path | None
    download_url: str | None
    elapsed_seconds: float
    error_message: str | None = None
