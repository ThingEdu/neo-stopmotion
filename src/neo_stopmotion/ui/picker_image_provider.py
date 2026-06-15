"""PickerImageProvider — T-005 live preview for the camera-picker popup.

Mirrors PreviewImageProvider but reads frames from CameraSelector's currently
probed engine rather than the main capture engine.  This allows the picker
popup to show a live image from whichever camera index is being evaluated.

When no probed camera is open (index failed / picker not active) the provider
returns a black placeholder image so QML gracefully shows nothing.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

import numpy as np
from numpy.typing import NDArray
from PyQt6.QtCore import QSize
from PyQt6.QtGui import QImage
from PyQt6.QtQuick import QQuickImageProvider

from neo_stopmotion.utils.cv_qt_bridge import cv_to_qimage

if TYPE_CHECKING:
    from neo_stopmotion.services.camera_selector import CameraSelector


_BLANK_FRAME: NDArray[np.uint8] = np.zeros((240, 320, 3), dtype=np.uint8)


class PickerImageProvider(QQuickImageProvider):
    """Serve live frames from the camera currently being probed in the picker.

    Call :meth:`set_selector` to inject the CameraSelector after it is created
    (avoids circular import in app.py).
    """

    def __init__(self) -> None:
        super().__init__(QQuickImageProvider.ImageType.Image)
        self._selector: CameraSelector | None = None

    def set_selector(self, selector: CameraSelector) -> None:
        """Inject (or replace) the CameraSelector instance."""
        self._selector = selector

    def requestImage(  # type: ignore[override]  # noqa: N802
        self,
        id: str,  # noqa: A002
        requestedSize: QSize,  # noqa: N803
    ) -> tuple[QImage, QSize]:
        raw: NDArray[np.uint8] | None = None
        if self._selector is not None:
            try:
                preview = self._selector.get_probed_preview()
                if isinstance(preview, np.ndarray):
                    raw = preview
            except Exception:  # noqa: BLE001
                raw = None

        frame: NDArray[np.uint8] = raw if raw is not None else _BLANK_FRAME
        qimg = cv_to_qimage(frame)
        return qimg, qimg.size()
