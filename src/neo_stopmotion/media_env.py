"""Qt Multimedia backend selection for the deployment targets.

Kept import-free and side-effect-free so it can run before Qt is imported
(and be unit-tested without a Qt install).
"""
from __future__ import annotations

from collections.abc import MutableMapping


def configure_media_backend(environ: MutableMapping[str, str], platform: str) -> None:
    """Point Qt Multimedia at a backend that can actually decode our MP4s.

    No-op outside Linux — macOS uses AVFoundation and plays H.264 natively.

    On NEO One (Armbian bookworm, aarch64) two things break video playback:

    1. Qt 6.7 defaults to the *ffmpeg* backend, but the PyQt6 wheel ships
       ``libffmpegmediaplugin.so`` linked against ``libav*.so.58`` (ffmpeg 4.x)
       while Debian 12 ships ffmpeg 5.x. The plugin fails to load, Qt gives up
       without trying GStreamer, and reports "No QtMultimedia backends found".
       Forcing ``gstreamer`` picks the plugin that links against system libs.
    2. GStreamer's decodebin then prefers the Allwinner stateless H.264 decoder
       ``v4l2slh264dec`` (rank 257 > avdec_h264's 256), which fails buffer
       allocation with "Internal data stream error". Demoting it falls back to
       the software decoder from ``gstreamer1.0-libav``.

    Uses setdefault so an operator can still override either value.
    """
    if not platform.startswith("linux"):
        return
    environ.setdefault("QT_MEDIA_BACKEND", "gstreamer")
    environ.setdefault("GST_PLUGIN_FEATURE_RANK", "v4l2slh264dec:NONE")
