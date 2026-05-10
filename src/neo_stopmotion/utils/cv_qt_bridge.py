from __future__ import annotations
import cv2
import numpy as np
from PyQt6.QtGui import QImage


def cv_to_qimage(bgr: np.ndarray | None) -> QImage:
    """Convert a BGR numpy array to QImage (RGB888). Returns null QImage on None."""
    if bgr is None:
        return QImage()
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    h, w, _ = rgb.shape
    bytes_per_line = 3 * w
    img = QImage(rgb.data, w, h, bytes_per_line, QImage.Format.Format_RGB888).copy()
    return img
