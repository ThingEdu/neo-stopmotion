"""Tests for the Qt Multimedia backend environment guard.

Root cause these guard against (verified on NEO One, Armbian bookworm aarch64):
- Qt 6.7 defaults to the ffmpeg media backend; the PyQt6 wheel's
  libffmpegmediaplugin.so links against libav*.so.58 (ffmpeg 4.x) while Debian 12
  ships ffmpeg 5.x, so the plugin fails to load and Qt reports
  "No QtMultimedia backends found" — video never plays.
- Once on GStreamer, the Allwinner stateless H.264 decoder (v4l2slh264dec,
  rank 257) outranks avdec_h264 (256) but fails buffer allocation.
"""
from neo_stopmotion.media_env import configure_media_backend


def test_forces_gstreamer_backend_on_linux() -> None:
    env: dict[str, str] = {}
    configure_media_backend(env, "linux")
    assert env["QT_MEDIA_BACKEND"] == "gstreamer"


def test_demotes_broken_allwinner_hw_decoder_on_linux() -> None:
    env: dict[str, str] = {}
    configure_media_backend(env, "linux")
    assert env["GST_PLUGIN_FEATURE_RANK"] == "v4l2slh264dec:NONE"


def test_is_a_noop_on_macos() -> None:
    env: dict[str, str] = {}
    configure_media_backend(env, "darwin")
    assert env == {}


def test_does_not_override_explicit_user_choice() -> None:
    env = {"QT_MEDIA_BACKEND": "ffmpeg", "GST_PLUGIN_FEATURE_RANK": "custom:MAX"}
    configure_media_backend(env, "linux")
    assert env["QT_MEDIA_BACKEND"] == "ffmpeg"
    assert env["GST_PLUGIN_FEATURE_RANK"] == "custom:MAX"
