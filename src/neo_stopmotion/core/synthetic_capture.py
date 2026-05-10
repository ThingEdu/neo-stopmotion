"""Synthetic capture source for dev/test on systems without webcam access.

Same interface as CaptureEngine but generates colorful test frames so the
full UI pipeline (preview → onion skin → capture → undo → export) can be
exercised without a physical camera or macOS camera permission grant.
"""
from __future__ import annotations
import time
import cv2
import numpy as np
from loguru import logger


class SyntheticCaptureEngine:
    """Drop-in replacement for CaptureEngine that synthesizes frames."""

    def __init__(
        self,
        resolution: tuple[int, int] = (1280, 720),
        onion_opacity: float = 0.30,
        **_ignored,
    ) -> None:
        self.resolution = resolution
        self.onion_opacity = onion_opacity
        self._last_frame: np.ndarray | None = None
        self._open = False
        self._tick = 0
        self._t0 = time.monotonic()

    @property
    def is_open(self) -> bool:
        return self._open

    def open(self) -> None:
        self._open = True
        logger.info(f"SyntheticCaptureEngine started ({self.resolution[0]}x{self.resolution[1]})")

    def _generate(self) -> np.ndarray:
        w, h = self.resolution
        self._tick += 1
        elapsed = time.monotonic() - self._t0

        # Cycling background hue
        hue = int((elapsed * 30) % 180)
        hsv = np.full((h, w, 3), (hue, 120, 240), dtype=np.uint8)
        bgr = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)

        # Animated circle
        cx = int(w / 2 + 300 * np.cos(elapsed * 1.2))
        cy = int(h / 2 + 200 * np.sin(elapsed * 1.5))
        cv2.circle(bgr, (cx, cy), 60, (255, 255, 255), -1)
        cv2.circle(bgr, (cx, cy), 60, (40, 40, 40), 4)

        # Big text
        text = "TEST FRAME"
        font = cv2.FONT_HERSHEY_DUPLEX
        fs = 2.5
        thickness = 4
        (tw, th), _ = cv2.getTextSize(text, font, fs, thickness)
        tx = (w - tw) // 2
        ty = h // 2 + th // 2
        cv2.putText(bgr, text, (tx + 3, ty + 3), font, fs, (40, 40, 40), thickness, cv2.LINE_AA)
        cv2.putText(bgr, text, (tx, ty), font, fs, (255, 255, 255), thickness, cv2.LINE_AA)

        # Tick + timestamp footer
        sub = f"tick={self._tick}  t={elapsed:5.1f}s"
        cv2.putText(bgr, sub, (40, h - 40), font, 1.0, (0, 0, 0), 3, cv2.LINE_AA)
        cv2.putText(bgr, sub, (40, h - 40), font, 1.0, (255, 255, 255), 1, cv2.LINE_AA)

        return bgr

    def capture_frame(self) -> np.ndarray:
        if not self._open:
            from neo_stopmotion.core.capture_engine import CaptureError
            raise CaptureError("SyntheticCaptureEngine not opened")
        frame = self._generate()
        self._last_frame = frame.copy()
        return frame

    def get_live_preview(self) -> np.ndarray | None:
        if not self._open:
            return None
        current = self._generate()
        if self._last_frame is None:
            return current
        return cv2.addWeighted(
            current, 1.0 - self.onion_opacity,
            self._last_frame, self.onion_opacity,
            0.0,
        )

    def set_last_frame(self, frame: np.ndarray | None) -> None:
        self._last_frame = frame.copy() if frame is not None else None

    def reset(self) -> None:
        self._last_frame = None

    def release(self) -> None:
        self._open = False
