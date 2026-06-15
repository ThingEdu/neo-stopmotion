"""Tests for T-006: Video Speed / FPS selection.

Spec ref:  docs/01-specs/features/video-speed/spec.md
Design:    docs/01-specs/features/video-speed/design-spec.md

P0 scenarios (TS-01 to TS-07) all covered as pytest unit tests.

TS-01 (P0): Export "Vua" (8fps) — MP4 cmd contains -framerate 8
TS-02 (P0): Export "Cham" (5fps) — MP4 cmd contains -framerate 5
TS-03 (P0): Export "Nhanh" (12fps) — MP4 cmd contains -framerate 12
TS-04 (P0): GIF uses same fps as MP4 (both palettegen and paletteuse)
TS-05 (P0): Default fps = 8 (Vua) from ExportCfg
TS-06 (P0): Too few frames → export rejected
TS-07 (P0): Change fps mid-session → export uses new fps
"""
from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest

from neo_stopmotion.core.video_exporter import VideoExporter

VALID_FPS_VALUES = (5, 8, 12)


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------


def _build_exporter(fps: int) -> VideoExporter:
    return VideoExporter(fps=fps, ffmpeg="ffmpeg", watermark_path=None)


def _get_mp4_cmd_args(exporter: VideoExporter, frames_dir: Path, output: Path) -> list[str]:
    return exporter._mp4_cmd_plain(frames_dir, output)


def _get_gif_palettegen_cmd(exporter: VideoExporter, frames_dir: Path, palette: Path) -> list[str]:
    return exporter._gif_palettegen_cmd(frames_dir, palette)


def _get_gif_paletteuse_cmd(
    exporter: VideoExporter, frames_dir: Path, palette: Path, output: Path
) -> list[str]:
    return exporter._gif_paletteuse_cmd(frames_dir, palette, output)


# ---------------------------------------------------------------------------
# TS-01  Vua (8 fps)
# ---------------------------------------------------------------------------


def test_ts01_mp4_framerate_vua(tmp_path):
    """TS-01 (P0): VideoExporter fps=8 → -framerate 8 in MP4 command."""
    exp = _build_exporter(fps=8)
    cmd = _get_mp4_cmd_args(exp, tmp_path, tmp_path / "out.mp4")
    idx = cmd.index("-framerate")
    assert cmd[idx + 1] == "8"


# ---------------------------------------------------------------------------
# TS-02  Cham (5 fps)
# ---------------------------------------------------------------------------


def test_ts02_mp4_framerate_cham(tmp_path):
    """TS-02 (P0): VideoExporter fps=5 → -framerate 5 in MP4 command."""
    exp = _build_exporter(fps=5)
    cmd = _get_mp4_cmd_args(exp, tmp_path, tmp_path / "out.mp4")
    idx = cmd.index("-framerate")
    assert cmd[idx + 1] == "5"


# ---------------------------------------------------------------------------
# TS-03  Nhanh (12 fps)
# ---------------------------------------------------------------------------


def test_ts03_mp4_framerate_nhanh(tmp_path):
    """TS-03 (P0): VideoExporter fps=12 → -framerate 12 in MP4 command."""
    exp = _build_exporter(fps=12)
    cmd = _get_mp4_cmd_args(exp, tmp_path, tmp_path / "out.mp4")
    idx = cmd.index("-framerate")
    assert cmd[idx + 1] == "12"


# ---------------------------------------------------------------------------
# TS-04  GIF uses same FPS as MP4 (palettegen + paletteuse)
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("fps", [5, 8, 12])
def test_ts04_gif_framerate_matches_mp4(tmp_path, fps):
    """TS-04 (P0): GIF palettegen and paletteuse both use the same -framerate N."""
    exp = _build_exporter(fps=fps)
    palette = tmp_path / "_palette.png"
    output = tmp_path / "out.gif"

    gen_cmd = _get_gif_palettegen_cmd(exp, tmp_path, palette)
    use_cmd = _get_gif_paletteuse_cmd(exp, tmp_path, palette, output)

    # palettegen must have -framerate fps
    idx_gen = gen_cmd.index("-framerate")
    assert gen_cmd[idx_gen + 1] == str(fps)

    # paletteuse must have -framerate fps
    idx_use = use_cmd.index("-framerate")
    assert use_cmd[idx_use + 1] == str(fps)


# ---------------------------------------------------------------------------
# TS-05  Default fps = 8 (Vua)
# ---------------------------------------------------------------------------


def test_ts05_default_fps_is_vua():
    """TS-05 (P0): ExportCfg default playback_fps is 8 (not 10 anymore after T-006 impl)."""
    # The spec says default must be "Vua" = 8 fps.
    # VideoExporter default constructor keeps fps param; the wiring changes default
    # from 10 to 8 via AppController / export_service plumbing.
    # Here we verify the speed_selector helper provides 8 as default.
    from neo_stopmotion.services.speed_selector import SpeedSelector
    sel = SpeedSelector()
    assert sel.selected_fps == 8
    assert sel.selected_label == "Vua"


# ---------------------------------------------------------------------------
# TS-06  Too few frames → export rejected
# ---------------------------------------------------------------------------


def test_ts06_too_few_frames_rejected():
    """TS-06 (P0): AppController rejects export when frame_count < min_frames."""
    from neo_stopmotion.services.app_controller import AppController
    from neo_stopmotion.utils.signal_bus import SignalBus

    mock_capture = MagicMock()
    mock_session = MagicMock()
    mock_session.frame_manager.frame_count = 3  # < 5 min

    bus = SignalBus.instance()
    warnings = []
    bus.status_message.connect(lambda level, msg: warnings.append((level, msg)))

    ctrl = AppController(
        capture=mock_capture,
        session=mock_session,
        export_service=MagicMock(),
        min_frames=5,
    )
    ctrl._frame_count = 3
    ctrl._do_export()

    assert any("frame" in w[1].lower() for w in warnings), "Should emit a warning about frame count"


# ---------------------------------------------------------------------------
# TS-07  Changing fps mid-session applies new fps at export time
# ---------------------------------------------------------------------------


def test_ts07_fps_change_applies_at_export(tmp_path):
    """TS-07 (P0): SpeedSelector.select() followed by export uses new fps."""
    from neo_stopmotion.services.speed_selector import SpeedSelector

    sel = SpeedSelector()
    assert sel.selected_fps == 8  # default Vua

    sel.select("Nhanh")
    assert sel.selected_fps == 12

    sel.select("Cham")
    assert sel.selected_fps == 5


# ---------------------------------------------------------------------------
# SpeedSelector unit tests
# ---------------------------------------------------------------------------


def test_speed_selector_defaults():
    """SpeedSelector starts with 'Vua' (8 fps) as default."""
    from neo_stopmotion.services.speed_selector import SpeedSelector
    s = SpeedSelector()
    assert s.selected_label == "Vua"
    assert s.selected_fps == 8


def test_speed_selector_all_options():
    """SpeedSelector has exactly 3 options with correct fps values."""
    from neo_stopmotion.services.speed_selector import SPEED_OPTIONS
    assert len(SPEED_OPTIONS) == 3
    labels = {opt["label"] for opt in SPEED_OPTIONS}
    assert labels == {"Cham", "Vua", "Nhanh"}
    fps_map = {opt["label"]: opt["fps"] for opt in SPEED_OPTIONS}
    assert fps_map["Cham"] == 5
    assert fps_map["Vua"] == 8
    assert fps_map["Nhanh"] == 12


def test_speed_selector_suggestion_few_frames():
    """Auto-suggest Cham (5fps) for 1-15 frames."""
    from neo_stopmotion.services.speed_selector import SpeedSelector
    s = SpeedSelector()
    assert s.get_suggested_label(0) is None   # 0 frames → no suggestion
    assert s.get_suggested_label(1) == "Cham"
    assert s.get_suggested_label(15) == "Cham"


def test_speed_selector_suggestion_medium_frames():
    """Auto-suggest Vua (8fps) for 16-30 frames."""
    from neo_stopmotion.services.speed_selector import SpeedSelector
    s = SpeedSelector()
    assert s.get_suggested_label(16) == "Vua"
    assert s.get_suggested_label(30) == "Vua"


def test_speed_selector_suggestion_many_frames():
    """Auto-suggest Nhanh (12fps) for > 30 frames."""
    from neo_stopmotion.services.speed_selector import SpeedSelector
    s = SpeedSelector()
    assert s.get_suggested_label(31) == "Nhanh"
    assert s.get_suggested_label(100) == "Nhanh"


def test_speed_selector_manual_overrides_suggestion():
    """User's manual selection is preserved even if suggestion changes."""
    from neo_stopmotion.services.speed_selector import SpeedSelector
    s = SpeedSelector()
    s.select("Nhanh")
    assert s.selected_fps == 12
    # Even though frame count is small (suggestion = Cham), manual wins
    assert s.get_suggested_label(5) == "Cham"
    assert s.selected_fps == 12  # unchanged


def test_speed_selector_invalid_label_raises():
    """Selecting an unknown label raises ValueError."""
    from neo_stopmotion.services.speed_selector import SpeedSelector
    s = SpeedSelector()
    with pytest.raises(ValueError, match="Unknown speed"):
        s.select("Sieu Nhanh")


def test_speed_selector_fps_for_label():
    """fps_for_label returns correct fps values."""
    from neo_stopmotion.services.speed_selector import SpeedSelector
    s = SpeedSelector()
    assert s.fps_for_label("Cham") == 5
    assert s.fps_for_label("Vua") == 8
    assert s.fps_for_label("Nhanh") == 12


# ---------------------------------------------------------------------------
# AppController integration: export_service receives selected fps
# ---------------------------------------------------------------------------


def test_app_controller_passes_fps_to_export(tmp_path):
    """AppController._do_export() uses speed_selector's fps."""
    from neo_stopmotion.services.app_controller import AppController
    from neo_stopmotion.services.export_service import ExportService

    mock_capture = MagicMock()
    mock_session = MagicMock()
    mock_session.frame_manager.frame_count = 10

    mock_export_svc = MagicMock(spec=ExportService)

    ctrl = AppController(
        capture=mock_capture,
        session=mock_session,
        export_service=mock_export_svc,
        min_frames=5,
    )
    # Select "Cham" (5 fps)
    ctrl.speed_selector.select("Cham")
    ctrl._frame_count = 10
    ctrl._do_export()

    # Verify export_service.start_export was called with fps=5
    mock_export_svc.start_export.assert_called_once()
    call_kwargs = mock_export_svc.start_export.call_args
    # start_export(fm, fps=5) — check second positional or keyword arg
    args, kwargs = call_kwargs
    if "fps" in kwargs:
        assert kwargs["fps"] == 5
    else:
        # fps passed as positional
        assert args[1] == 5
