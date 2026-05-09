from __future__ import annotations
from PyQt6.QtCore import QSize
from PyQt6.QtGui import QImage
from PyQt6.QtQuick import QQuickImageProvider

from neo_stopmotion.core.capture_engine import CaptureEngine
from neo_stopmotion.utils.cv_qt_bridge import cv_to_qimage


class PreviewImageProvider(QQuickImageProvider):
    """Provide live (onion-skinned) preview frames to QML."""

    def __init__(self, capture_engine: CaptureEngine) -> None:
        super().__init__(QQuickImageProvider.ImageType.Image)
        self._capture = capture_engine

    def requestImage(self, id: str, requestedSize: QSize, size: QSize) -> tuple[QImage, QSize]:
        frame = self._capture.get_live_preview()
        qimg = cv_to_qimage(frame)
        return qimg, qimg.size()
