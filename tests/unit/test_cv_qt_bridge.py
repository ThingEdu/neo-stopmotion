import numpy as np
from PyQt6.QtGui import QImage
from neo_stopmotion.utils.cv_qt_bridge import cv_to_qimage


def test_cv_to_qimage_shape():
    bgr = np.full((480, 640, 3), 200, dtype=np.uint8)
    qimg = cv_to_qimage(bgr)
    assert isinstance(qimg, QImage)
    assert qimg.width() == 640
    assert qimg.height() == 480


def test_cv_to_qimage_handles_none():
    qimg = cv_to_qimage(None)
    assert qimg.isNull()
