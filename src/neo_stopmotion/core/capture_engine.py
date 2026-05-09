from __future__ import annotations
import time
import cv2
import numpy as np
from loguru import logger


class CaptureError(RuntimeError):
    pass


class CaptureEngine:
    """Read frames from a USB webcam via OpenCV."""

    def __init__(
        self,
        webcam_index: int = 0,
        resolution: tuple[int, int] = (1280, 720),
        retry_count: int = 3,
        retry_delay_seconds: float = 1.0,
    ) -> None:
        self.webcam_index = webcam_index
        self.resolution = resolution
        self.retry_count = retry_count
        self.retry_delay_seconds = retry_delay_seconds
        self._cap: cv2.VideoCapture | None = None
        self._last_frame: np.ndarray | None = None

    @property
    def is_open(self) -> bool:
        return self._cap is not None and self._cap.isOpened()

    def open(self) -> None:
        last_err: Exception | None = None
        for attempt in range(1, self.retry_count + 1):
            try:
                cap = cv2.VideoCapture(self.webcam_index)
                if not cap.isOpened():
                    raise CaptureError(f"Cannot open webcam index {self.webcam_index}")
                cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.resolution[0])
                cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.resolution[1])
                self._cap = cap
                logger.info(f"Webcam opened (index={self.webcam_index}, attempt={attempt})")
                return
            except Exception as e:
                last_err = e
                logger.warning(f"Webcam open attempt {attempt} failed: {e}")
                time.sleep(self.retry_delay_seconds)
        raise CaptureError(f"Failed to open webcam after {self.retry_count} retries") from last_err

    def capture_frame(self) -> np.ndarray:
        if self._cap is None:
            raise CaptureError("Webcam not opened")
        ret, frame = self._cap.read()
        if not ret or frame is None:
            raise CaptureError("Failed to read frame from webcam")
        self._last_frame = frame.copy()
        return frame

    def get_live_preview(self) -> np.ndarray | None:
        """Read a frame for preview. Onion skin added in T2.2."""
        if self._cap is None:
            return None
        ret, frame = self._cap.read()
        if not ret or frame is None:
            return None
        return frame

    def reset(self) -> None:
        self._last_frame = None

    def release(self) -> None:
        if self._cap is not None:
            self._cap.release()
            self._cap = None
