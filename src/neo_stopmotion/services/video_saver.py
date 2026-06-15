"""VideoSaver — T-007 save-video feature.

Provides two operations for SuccessPage:
1. save(mp4_path, dest_dir) — copy MP4 to a user-selected directory.
2. copy_link(url) — copy share URL to clipboard.

Both operations emit save_video_result(bool, str) on SignalBus so the
QML toast can react without blocking the UI thread.

Spec ref:  docs/01-specs/features/save-video/spec.md
Design:    docs/01-specs/features/save-video/design-spec.md
"""
from __future__ import annotations

import shutil
from pathlib import Path

from loguru import logger

from neo_stopmotion.utils.signal_bus import SignalBus


class VideoSaver:
    """Copy a video file to a destination directory."""

    def save(self, mp4_path: str, dest_dir: str) -> None:
        """Copy *mp4_path* into *dest_dir*.

        Emits ``save_video_result(True, full_dest_path)`` on success,
        ``save_video_result(False, error_message)`` on failure.
        Source file is never modified.
        """
        bus = SignalBus.instance()
        src = Path(mp4_path)
        dst_dir = Path(dest_dir)

        if not src.exists():
            msg = f"Không tìm thấy file phim: {src}"
            logger.warning(f"VideoSaver.save: {msg}")
            bus.save_video_result.emit(False, msg)
            return

        if not dst_dir.exists():
            msg = "Thư mục không tìm thấy (có thể USB đã rút). Thử lại nhé!"
            logger.warning(f"VideoSaver.save: dest {dst_dir} does not exist")
            bus.save_video_result.emit(False, msg)
            return

        dest_file = dst_dir / src.name
        try:
            shutil.copy2(str(src), str(dest_file))
            logger.info(f"Video saved: {dest_file}")
            bus.save_video_result.emit(True, str(dest_file))
        except PermissionError:
            msg = "Không đủ quyền lưu tại thư mục đó. Chọn thư mục khác nhé!"
            logger.warning(f"VideoSaver.save: permission error writing to {dest_file}")
            bus.save_video_result.emit(False, msg)
        except OSError as e:
            if "No space" in str(e) or "28" in str(e.errno or ""):
                msg = "Không đủ dung lượng. Xoá bớt file rồi thử lại nhé!"
            else:
                msg = f"Lưu không thành công. Thử lại nhé! ({e})"
            logger.error(f"VideoSaver.save: OS error: {e}")
            bus.save_video_result.emit(False, msg)

    def copy_link(self, url: str) -> None:
        """Copy *url* to system clipboard.

        No-op if *url* is empty.
        Emits ``save_video_result(True, "Đã sao chép link!")`` on success.
        """
        if not url:
            return
        bus = SignalBus.instance()
        try:
            self._set_clipboard(url)
            bus.save_video_result.emit(True, "Đã sao chép link!")
            logger.info(f"Link copied to clipboard: {url}")
        except Exception as e:  # noqa: BLE001
            msg = f"Không sao chép được link: {e}"
            logger.warning(f"VideoSaver.copy_link: {e}")
            bus.save_video_result.emit(False, msg)

    def _set_clipboard(self, text: str) -> None:
        """Write *text* to system clipboard via PyQt6 or subprocess fallback."""
        try:
            from PyQt6.QtGui import QGuiApplication
            cb = QGuiApplication.clipboard()
            if cb is not None:
                cb.setText(text)
                return
        except Exception:  # noqa: BLE001
            pass
        # Fallback: subprocess pbcopy (macOS) / xclip (Linux)
        import subprocess
        import sys
        if sys.platform == "darwin":
            subprocess.run(["pbcopy"], input=text.encode(), check=True)
        else:
            subprocess.run(["xclip", "-selection", "clipboard"], input=text.encode(), check=True)
