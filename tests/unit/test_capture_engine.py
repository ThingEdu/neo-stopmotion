import numpy as np
import pytest
from unittest.mock import MagicMock, patch
from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError


@pytest.fixture
def fake_frame():
    return np.full((720, 1280, 3), 128, dtype=np.uint8)


def test_open_success(fake_frame):
    fake_cap = MagicMock()
    fake_cap.isOpened.return_value = True
    fake_cap.read.return_value = (True, fake_frame)
    with patch("cv2.VideoCapture", return_value=fake_cap):
        eng = CaptureEngine(webcam_index=0, resolution=(1280, 720))
        eng.open()
        assert eng.is_open is True


def test_open_retry_then_fail():
    fake_cap = MagicMock()
    fake_cap.isOpened.return_value = False
    with patch("cv2.VideoCapture", return_value=fake_cap):
        eng = CaptureEngine(webcam_index=99, retry_count=2)
        with pytest.raises(CaptureError, match="webcam"):
            eng.open()


def test_capture_frame_returns_numpy(fake_frame):
    fake_cap = MagicMock()
    fake_cap.isOpened.return_value = True
    fake_cap.read.return_value = (True, fake_frame)
    with patch("cv2.VideoCapture", return_value=fake_cap):
        eng = CaptureEngine()
        eng.open()
        frame = eng.capture_frame()
        assert frame.shape == (720, 1280, 3)
