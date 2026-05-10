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


def test_get_live_preview_no_blend_when_no_last_frame():
    fake_cap = MagicMock()
    fake_cap.isOpened.return_value = True
    fake_cap.read.return_value = (True, np.full((720, 1280, 3), 100, dtype=np.uint8))
    with patch("cv2.VideoCapture", return_value=fake_cap):
        eng = CaptureEngine(onion_opacity=0.3)
        eng.open()
        preview = eng.get_live_preview()
        assert preview[0, 0, 0] == 100  # no blending


def test_get_live_preview_blends_with_last_frame():
    current = np.full((720, 1280, 3), 200, dtype=np.uint8)
    last = np.full((720, 1280, 3), 0, dtype=np.uint8)
    fake_cap = MagicMock()
    fake_cap.isOpened.return_value = True
    fake_cap.read.return_value = (True, current.copy())
    with patch("cv2.VideoCapture", return_value=fake_cap):
        eng = CaptureEngine(onion_opacity=0.3)
        eng.open()
        eng._last_frame = last
        preview = eng.get_live_preview()
        # 200*0.7 + 0*0.3 = 140
        assert 138 <= preview[0, 0, 0] <= 142


def test_capture_frame_does_not_blend(fake_frame):
    fake_cap = MagicMock()
    fake_cap.isOpened.return_value = True
    fake_cap.read.return_value = (True, fake_frame.copy())
    with patch("cv2.VideoCapture", return_value=fake_cap):
        eng = CaptureEngine(onion_opacity=0.3)
        eng.open()
        eng._last_frame = np.zeros((720, 1280, 3), dtype=np.uint8)
        frame = eng.capture_frame()
        # captured frame must be raw (NOT blended)
        assert frame[0, 0, 0] == 128
