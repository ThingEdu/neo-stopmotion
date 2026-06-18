"""Tests for T-005: Camera Select feature.

Maps to spec: docs/01-specs/features/camera-select/spec.md
Design ref:   docs/01-specs/features/camera-select/design-spec.md

TS-01 (P0): Happy path — select camera, webcam_ready emitted
TS-02 (P0): Config written after selection
TS-03 (P0): Unavailable camera index shows error state, does not crash
TS-04 (P0): Cancel picker keeps original camera
TS-05 (P0): No camera found at any index 0-5
TS-06 (P0): Env override takes priority over config write
TS-07 (P1): Index wraps around 0→5→0 (cycle)
TS-08 (P0): PickerImageProvider returns frame when selector has probed camera
TS-09 (P0): PickerImageProvider returns blank frame when no probed camera
TS-10 (P1): Config write succeeds when dir exists
TS-11 (P1): Config write failure is non-fatal (just logs)
TS-12 (P0): AppController.pickerCounter increments on successful probe
"""
from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

import numpy as np
import pytest

from neo_stopmotion.services.camera_selector import CameraSelector

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def mock_capture_factory():
    """Factory that returns a mock CaptureEngine per webcam index."""
    def _factory(index: int) -> MagicMock:
        cap = MagicMock()
        cap.webcam_index = index
        cap.is_open = True
        cap.open.return_value = None
        cap.release.return_value = None
        cap.get_live_preview.return_value = None
        return cap
    return _factory


@pytest.fixture
def selector(tmp_path):
    """CameraSelector with a fake current_capture (index 0), real tmp config dir."""
    current_cap = MagicMock()
    current_cap.webcam_index = 0
    current_cap.is_open = True
    config_path = tmp_path / "config.toml"
    return CameraSelector(
        current_capture=current_cap,
        config_path=config_path,
    )


# ---------------------------------------------------------------------------
# TS-01  Happy path: probe index 1, confirm → webcam_ready emitted, index updated
# ---------------------------------------------------------------------------


def test_ts01_select_camera_happy_path(selector):
    """TS-01 (P0): probe index returns is_open=True, confirm applies it."""
    from neo_stopmotion.utils.signal_bus import SignalBus
    bus = SignalBus.instance()
    ready_emitted = []
    bus.webcam_ready.connect(lambda: ready_emitted.append(True))

    # Simulate probing index 1 succeeds
    with patch.object(selector, "_try_open_index") as mock_try:
        mock_cap = MagicMock()
        mock_cap.is_open = True
        mock_cap.webcam_index = 1
        mock_try.return_value = (mock_cap, True)

        result = selector.probe_index(1)
        assert result is True  # camera is available

    # Confirm selection
    selector.confirm_selection(new_index=1)
    assert selector.selected_index == 1
    assert ready_emitted, "webcam_ready must be emitted after confirm"


# ---------------------------------------------------------------------------
# TS-02  Config written after selection
# ---------------------------------------------------------------------------


def test_ts02_config_written_after_selection(selector, tmp_path):
    """TS-02 (P0): config file updated with new webcam_index."""
    config_path = tmp_path / "config.toml"
    selector._config_path = config_path

    with patch.object(selector, "_try_open_index") as mock_try:
        mock_cap = MagicMock()
        mock_cap.is_open = True
        mock_cap.webcam_index = 1
        mock_try.return_value = (mock_cap, True)
        selector.probe_index(1)

    selector.confirm_selection(new_index=1)

    assert config_path.exists(), "config.toml must be written"
    content = config_path.read_text()
    assert "webcam_index" in content
    assert "1" in content


# ---------------------------------------------------------------------------
# TS-03  Camera at probed index is unavailable → is_available=False
# ---------------------------------------------------------------------------


def test_ts03_camera_unavailable_probe(selector):
    """TS-03 (P0): probe_index returns False when camera cannot open."""
    with patch.object(selector, "_try_open_index") as mock_try:
        mock_try.return_value = (None, False)
        result = selector.probe_index(3)
    assert result is False


# ---------------------------------------------------------------------------
# TS-04  Cancel keeps original camera
# ---------------------------------------------------------------------------


def test_ts04_cancel_keeps_original(selector):
    """TS-04 (P0): cancel_selection keeps original webcam_index."""
    original_index = selector._current_capture.webcam_index

    with patch.object(selector, "_try_open_index") as mock_try:
        mock_cap = MagicMock()
        mock_cap.is_open = True
        mock_cap.webcam_index = 2
        mock_try.return_value = (mock_cap, True)
        selector.probe_index(2)

    selector.cancel_selection()
    assert selector.selected_index == original_index


# ---------------------------------------------------------------------------
# TS-05  No camera found (indices 0-5 all fail)
# ---------------------------------------------------------------------------


def test_ts05_no_camera_found(selector):
    """TS-05 (P0): probe_any returns False when all 0-5 fail."""
    with patch.object(selector, "_try_open_index") as mock_try:
        mock_try.return_value = (None, False)
        result = selector.probe_any()
    assert result is False


# ---------------------------------------------------------------------------
# TS-06  Env override not overwritten by config write
# ---------------------------------------------------------------------------


def test_ts06_env_override_not_overwritten(selector, tmp_path, monkeypatch):
    """TS-06 (P0): NEO_STOPMOTION_WEBCAM_INDEX env var not overwritten."""
    monkeypatch.setenv("NEO_STOPMOTION_WEBCAM_INDEX", "2")
    config_path = tmp_path / "config.toml"
    selector._config_path = config_path

    # User selects index 1 — config should store 1 but env still takes precedence
    with patch.object(selector, "_try_open_index") as mock_try:
        mock_cap = MagicMock()
        mock_cap.is_open = True
        mock_cap.webcam_index = 1
        mock_try.return_value = (mock_cap, True)
        selector.probe_index(1)

    selector.confirm_selection(new_index=1)
    # Config stores user preference (1)
    assert config_path.exists()
    content = config_path.read_text()
    assert "webcam_index" in content
    # The env var (2) is separate concern — loading settings would pick env
    # (tested in test_settings.py). Here just verify config does NOT override env.
    from neo_stopmotion.config.settings import load_settings
    s = load_settings(user_config_path=config_path)
    assert s.capture.webcam_index == 2  # env wins


# ---------------------------------------------------------------------------
# TS-07  Index wraps around cyclically
# ---------------------------------------------------------------------------


def test_ts07_index_cycle_forward(selector):
    """TS-07 (P1): next_index wraps 5 → 0."""
    assert selector.next_index(5) == 0
    assert selector.next_index(0) == 1
    assert selector.next_index(4) == 5


def test_ts07_index_cycle_backward(selector):
    """TS-07 (P1): prev_index wraps 0 → 5."""
    assert selector.prev_index(0) == 5
    assert selector.prev_index(5) == 4
    assert selector.prev_index(1) == 0


# ---------------------------------------------------------------------------
# TS-10  Config write succeeds
# ---------------------------------------------------------------------------


def test_ts10_config_write_success(selector, tmp_path):
    """TS-10 (P1): config written without error when dir exists."""
    config_path = tmp_path / "config.toml"
    selector._config_path = config_path
    selector._write_config(webcam_index=3)
    assert config_path.exists()
    content = config_path.read_text()
    assert "[capture]" in content
    assert "webcam_index = 3" in content


# ---------------------------------------------------------------------------
# TS-11  Config write failure is non-fatal
# ---------------------------------------------------------------------------


def test_ts11_config_write_failure_nonfatal(selector, tmp_path, caplog):
    """TS-11 (P1): config write failure does not crash; logs warning."""
    bad_path = Path("/nonexistent_dir/config.toml")
    selector._config_path = bad_path
    # Should not raise
    selector._write_config(webcam_index=1)
    # Signal bus still OK — confirm still works
    selector.confirm_selection(new_index=0)


# ---------------------------------------------------------------------------
# Helper: _write_config produces valid TOML
# ---------------------------------------------------------------------------


def test_write_config_format(selector, tmp_path):
    """_write_config produces [capture] section with webcam_index."""
    config_path = tmp_path / "config.toml"
    selector._config_path = config_path
    selector._write_config(webcam_index=2)
    text = config_path.read_text()
    assert text.strip().startswith("[capture]")
    assert "webcam_index = 2" in text


def test_write_config_merges_existing(selector, tmp_path):
    """_write_config merges into existing config without wiping other sections."""
    config_path = tmp_path / "config.toml"
    config_path.write_text("[uart]\nport = \"auto\"\n")
    selector._config_path = config_path
    selector._write_config(webcam_index=3)
    text = config_path.read_text()
    assert "webcam_index = 3" in text
    assert "port" in text  # existing section preserved


# ---------------------------------------------------------------------------
# TS-08  PickerImageProvider returns real frame when selector has probed camera
# ---------------------------------------------------------------------------


def test_ts08_picker_provider_returns_frame(tmp_path):
    """TS-08 (P0): PickerImageProvider delegates get_probed_preview() to selector."""
    from PyQt6.QtCore import QSize

    from neo_stopmotion.ui.picker_image_provider import PickerImageProvider

    fake_frame = np.zeros((240, 320, 3), dtype=np.uint8)
    fake_frame[0, 0] = [1, 2, 3]  # non-black to detect real frame

    mock_sel = MagicMock()
    mock_sel.get_probed_preview.return_value = fake_frame

    provider = PickerImageProvider()
    provider.set_selector(mock_sel)

    qimg, size = provider.requestImage("0", QSize(320, 240))
    mock_sel.get_probed_preview.assert_called_once()
    assert not qimg.isNull()
    assert qimg.width() == 320
    assert qimg.height() == 240


# ---------------------------------------------------------------------------
# TS-09  PickerImageProvider returns blank frame when no probed camera
# ---------------------------------------------------------------------------


def test_ts09_picker_provider_blank_when_no_camera():
    """TS-09 (P0): PickerImageProvider returns black placeholder when selector is None."""
    from PyQt6.QtCore import QSize

    from neo_stopmotion.ui.picker_image_provider import PickerImageProvider

    provider = PickerImageProvider()  # no selector injected
    qimg, size = provider.requestImage("0", QSize(320, 240))
    assert not qimg.isNull()
    # Blank frame is 320×240
    assert qimg.width() == 320
    assert qimg.height() == 240


def test_ts09b_picker_provider_blank_when_preview_returns_none():
    """TS-09b (P0): returns blank placeholder when get_probed_preview() returns None."""
    from PyQt6.QtCore import QSize

    from neo_stopmotion.ui.picker_image_provider import PickerImageProvider

    mock_sel = MagicMock()
    mock_sel.get_probed_preview.return_value = None

    provider = PickerImageProvider()
    provider.set_selector(mock_sel)
    qimg, _ = provider.requestImage("0", QSize(320, 240))
    assert not qimg.isNull()


# ---------------------------------------------------------------------------
# TS-12  AppController.pickerCounter increments on successful probe
# ---------------------------------------------------------------------------


def test_ts12_picker_counter_increments_on_success():
    """TS-12 (P0): pickerCounter goes up after each successful probe_index."""
    from neo_stopmotion.services.app_controller import AppController
    from neo_stopmotion.services.export_service import ExportService
    from neo_stopmotion.services.session_service import SessionService

    # Minimal mocks
    mock_capture = MagicMock()
    mock_capture.webcam_index = 0
    mock_session = MagicMock(spec=SessionService)
    mock_session.frame_manager = MagicMock()
    mock_session.frame_manager.frame_count = 0
    mock_session.frame_manager.get_all_frames.return_value = []

    mock_sel = MagicMock(spec=CameraSelector)
    mock_sel.probe_index.return_value = True  # always succeeds

    ctrl = AppController(
        capture=mock_capture,
        session=mock_session,
        export_service=MagicMock(spec=ExportService),
        camera_selector=mock_sel,
    )

    before = ctrl.pickerCounter
    ctrl.picker_probe_index(1)
    assert ctrl.pickerCounter == before + 1

    ctrl.picker_probe_index(2)
    assert ctrl.pickerCounter == before + 2


def test_ts12b_picker_counter_no_change_on_failed_probe():
    """TS-12b (P0): pickerCounter stays the same when probe_index returns False."""
    from neo_stopmotion.services.app_controller import AppController
    from neo_stopmotion.services.export_service import ExportService
    from neo_stopmotion.services.session_service import SessionService

    mock_capture = MagicMock()
    mock_capture.webcam_index = 0
    mock_session = MagicMock(spec=SessionService)
    mock_session.frame_manager = MagicMock()
    mock_session.frame_manager.frame_count = 0
    mock_session.frame_manager.get_all_frames.return_value = []

    mock_sel = MagicMock(spec=CameraSelector)
    mock_sel.probe_index.return_value = False  # always fails

    ctrl = AppController(
        capture=mock_capture,
        session=mock_session,
        export_service=MagicMock(spec=ExportService),
        camera_selector=mock_sel,
    )

    before = ctrl.pickerCounter
    ctrl.picker_probe_index(3)
    assert ctrl.pickerCounter == before  # unchanged


# ---------------------------------------------------------------------------
# Regression: synthetic fallback engine (no webcam_index) must not crash
# the "Đổi camera" picker flow (bug 2026-06-16).
# ---------------------------------------------------------------------------


class _NoIndexEngine:
    """Mimics SyntheticCaptureEngine: a capture engine WITHOUT webcam_index."""

    def release(self) -> None:
        pass


def test_selected_index_when_engine_has_no_webcam_index():
    """selected_index must return 0 (not raise AttributeError) for synthetic engine."""
    sel = CameraSelector(current_capture=_NoIndexEngine())  # type: ignore[arg-type]
    assert sel.selected_index == 0


def test_cancel_selection_with_no_webcam_index_does_not_crash():
    """Cancelling the picker with a synthetic engine must not raise."""
    sel = CameraSelector(current_capture=_NoIndexEngine())  # type: ignore[arg-type]
    sel.cancel_selection()  # must not raise


# ---------------------------------------------------------------------------
# T-015 REPRODUCE-FIRST — Wave 5 (2026-06-19)
# Bug: CameraPickerPopup hardcodes 6 slots regardless of real cameras present.
# Root cause: CameraSelector has no list_available_indices(); AppController has
# no get_available_camera_indices() slot; QML uses model:6 / % 6 hardcoded.
#
# ALL tests below MUST FAIL before T-016 fix is applied.
# After T-016 fix they MUST PASS.
# ---------------------------------------------------------------------------


def test_list_available_indices_returns_only_working_cameras(tmp_path):
    """EXPECTED: FAIL before fix (T-016). Bug: list_available_indices() does not exist.

    When only index 0 is functional, list_available_indices() must return [0].
    Currently fails with AttributeError because the method is missing.
    """
    from unittest.mock import patch

    current_cap = MagicMock()
    current_cap.webcam_index = 0
    sel = CameraSelector(current_capture=current_cap, config_path=tmp_path / "cfg.toml")

    def fake_try_open(index: int):
        if index == 0:
            cap = MagicMock()
            cap.is_open = True
            return cap, True
        return None, False

    with patch.object(sel, "_try_open_index", side_effect=fake_try_open):
        result = sel.list_available_indices()  # AttributeError before fix

    assert result == [0], f"Expected [0], got {result}"


def test_list_available_indices_empty_when_no_camera(tmp_path):
    """EXPECTED: FAIL before fix (T-016). Bug: list_available_indices() does not exist.

    When all indices 0-5 fail, list_available_indices() must return [].
    Currently fails with AttributeError because the method is missing.
    """
    current_cap = MagicMock()
    current_cap.webcam_index = 0
    sel = CameraSelector(current_capture=current_cap, config_path=tmp_path / "cfg.toml")

    with patch.object(sel, "_try_open_index", return_value=(None, False)):
        result = sel.list_available_indices()  # AttributeError before fix

    assert result == [], f"Expected [], got {result}"


def test_list_available_indices_uses_zero_retry_delay(tmp_path):
    """EXPECTED: FAIL before fix (T-016). Bug: list_available_indices() does not exist.

    Probe during enumerate must use retry_delay_seconds=0 to avoid ~6s blocking.
    The existing _try_open_index uses retry_count=1 but retry_delay_seconds defaults
    to 1.0 — enumerate must explicitly pass 0.
    Verify by patching CaptureEngine and inspecting constructor kwargs.
    """
    from neo_stopmotion.core.capture_engine import CaptureEngine

    current_cap = MagicMock()
    current_cap.webcam_index = 0
    sel = CameraSelector(current_capture=current_cap, config_path=tmp_path / "cfg.toml")

    constructed_delays: list[float] = []

    original_init = CaptureEngine.__init__

    def spy_init(self, *args, **kwargs):  # type: ignore[override]
        constructed_delays.append(kwargs.get("retry_delay_seconds", 1.0))
        original_init(self, *args, **kwargs)

    with patch.object(CaptureEngine, "__init__", spy_init):
        with patch.object(CaptureEngine, "open", return_value=None):
            with patch.object(CaptureEngine, "is_open", new_callable=lambda: property(lambda self: False)):
                try:
                    sel.list_available_indices()  # AttributeError before fix
                except AttributeError:
                    raise  # re-raise to keep FAIL semantics

    assert all(d == 0.0 for d in constructed_delays), (
        f"Expected all retry_delay_seconds=0 during enumerate, got: {constructed_delays}"
    )


def test_appcontroller_slot_returns_available_indices():
    """EXPECTED: FAIL before fix (T-016). Bug: get_available_camera_indices() slot missing.

    AppController must expose a pyqtSlot get_available_camera_indices() that
    returns a list of int (available camera indices) for QML to use as model.
    Currently fails with AttributeError because the slot does not exist.
    """
    from neo_stopmotion.services.app_controller import AppController
    from neo_stopmotion.services.export_service import ExportService

    mock_capture = MagicMock()
    mock_capture.webcam_index = 0
    mock_session = MagicMock()
    mock_session.frame_manager.frame_count = 0

    mock_sel = MagicMock(spec=CameraSelector)
    mock_sel.list_available_indices.return_value = [0]

    ctrl = AppController(
        capture=mock_capture,
        session=mock_session,
        export_service=MagicMock(spec=ExportService),
        camera_selector=mock_sel,
    )

    result = ctrl.get_available_camera_indices()  # AttributeError before fix
    assert isinstance(result, list), f"Expected list, got {type(result)}"
    assert all(isinstance(i, int) for i in result), f"All elements must be int: {result}"


def test_hotplug_guard_qml_has_no_camera_condition_in_timer():
    """EXPECTED: FAIL before fix (T-016). Bug: QML Timer runs unconditionally when popup open.

    The hot-plug re-scan Timer in CameraPickerPopup.qml must have its 'running'
    property bound to both root.opened AND root.noCamera — so it never runs when
    the popup is open and cameras are already found (preventing USB bus hammering).

    This test reads the QML file and asserts the Timer binding includes 'noCamera'.
    Currently FAILS because the Timer only checks root.opened (or doesn't exist yet).
    """
    import re

    qml_path = (
        Path(__file__).parent.parent.parent
        / "src/neo_stopmotion/ui/qml/components/CameraPickerPopup.qml"
    )
    assert qml_path.exists(), f"QML file not found: {qml_path}"

    content = qml_path.read_text(encoding="utf-8")

    # Look for a Timer with running: bound to noCamera condition
    # After fix: Timer { interval: 2000; running: root.opened && root.noCamera; ... }
    hotplug_timer_pattern = re.compile(
        r"Timer\b[^}]*?running\s*:\s*[^\n]*noCamera[^\n]*",
        re.DOTALL,
    )
    match = hotplug_timer_pattern.search(content)

    assert match is not None, (
        "Hot-plug Timer in CameraPickerPopup.qml must have 'running' bound to a condition "
        "that includes 'noCamera' to prevent background scanning when cameras are present. "
        "Found no such Timer — T-016 fix required."
    )
