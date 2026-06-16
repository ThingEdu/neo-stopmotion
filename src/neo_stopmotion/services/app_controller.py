from __future__ import annotations

from pathlib import Path

from loguru import logger
from PyQt6.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot

from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError
from neo_stopmotion.services.camera_selector import CameraSelector
from neo_stopmotion.services.export_service import ExportService
from neo_stopmotion.services.library_service import LibraryService
from neo_stopmotion.services.session_service import SessionService
from neo_stopmotion.services.speed_selector import SpeedSelector
from neo_stopmotion.services.video_saver import VideoSaver
from neo_stopmotion.utils.signal_bus import SignalBus


class AppController(QObject):
    """Root QObject exposed to QML — facade over capture+session+export."""

    frameCountChanged = pyqtSignal(int)
    # T-005: camera picker signals
    cameraProbeResult = pyqtSignal(int, bool)  # (index, is_available)
    cameraChanged = pyqtSignal(int)  # new webcam_index
    pickerCounterChanged = pyqtSignal(int)  # bump to force image reload in picker

    def __init__(
        self,
        capture: CaptureEngine,
        session: SessionService,
        export_service: ExportService | None = None,
        min_frames: int = 5,
        camera_selector: CameraSelector | None = None,
        library_service: LibraryService | None = None,
    ) -> None:
        super().__init__()
        self._capture = capture
        self._session = session
        self._export_service = export_service
        self._min_frames = min_frames
        self._bus = SignalBus.instance()
        self._frame_count = 0
        self._post_export = False  # True when on SuccessPage
        # T-005: camera selector (lazy init if not provided)
        self._camera_selector: CameraSelector | None = camera_selector
        # T-005: picker preview counter — bumped each time a probe succeeds so QML
        # refreshes image://picker/<counter> immediately.
        self._picker_counter: int = 0
        # T-006: speed selector (default Vua / 8 fps)
        self.speed_selector = SpeedSelector()
        # T-012: library service (injected from app.py)
        self._library_service: LibraryService | None = library_service
        self._bus.uart_command_received.connect(self.handle_uart_command)
        self._bus.export_completed.connect(self._on_export_completed)

    def _on_export_completed(self, _payload: dict) -> None:
        self._post_export = True

    @pyqtProperty(int, notify=frameCountChanged)
    def frameCount(self) -> int:
        return self._frame_count

    @pyqtProperty(int, notify=pickerCounterChanged)
    def pickerCounter(self) -> int:
        """Monotonically increasing counter; QML uses it as image URL suffix."""
        return self._picker_counter

    @pyqtSlot(str)
    def handle_uart_command(self, cmd: str) -> None:
        cmd = cmd.strip().upper()
        logger.debug(f"UART cmd: {cmd}")
        if cmd == "SHOOT":
            self._do_shoot()
        elif cmd == "UNDO":
            self._do_undo()
        elif cmd == "EXPORT":
            self._do_export()
        elif cmd == "READY":
            logger.info("ThingBot READY")
        elif cmd == "BAT_LOW":
            self._bus.status_message.emit("warning", "Pin ThingBot yếu")
        else:
            logger.warning(f"Unknown UART cmd: {cmd}")

    def _do_shoot(self) -> None:
        # On SuccessPage: SHOOT means "I want to make another film".
        # Auto-reset and capture the first frame of a new session.
        if self._post_export:
            logger.info("SHOOT after export — auto-resetting session for new film")
            self.reset_session()
        try:
            frame = self._capture.capture_frame()
        except CaptureError as e:
            logger.error(f"Capture failed: {e}")
            self._bus.webcam_error.emit(str(e))
            return
        path = self._session.frame_manager.add_frame(frame)
        self._frame_count = self._session.frame_manager.frame_count
        self.frameCountChanged.emit(self._frame_count)
        self._bus.frame_captured.emit(self._frame_count, str(path))

    def _do_undo(self) -> None:
        ok = self._session.frame_manager.undo_last_frame()
        if not ok:
            return
        new_count = self._session.frame_manager.frame_count
        prev = self._session.frame_manager.load_frame(new_count) if new_count > 0 else None
        self._capture.set_last_frame(prev)
        self._frame_count = new_count
        self.frameCountChanged.emit(self._frame_count)
        self._bus.frame_undone.emit(new_count)

    def _do_export(self) -> None:
        fm = self._session.frame_manager
        if fm.frame_count < self._min_frames:
            self._bus.status_message.emit(
                "warning",
                f"Cần ít nhất {self._min_frames} frame — con chụp thêm vài tấm nữa nha!",
            )
            return
        if self._export_service is None:
            logger.warning("Export requested but ExportService not configured")
            return
        # T-006: pass selected fps to export service
        fps = self.speed_selector.selected_fps
        logger.info(f"Export started with fps={fps} ({self.speed_selector.selected_label})")
        self._export_service.start_export(fm, fps=fps)

    # ------------------------------------------------------------------
    # T-006: Speed selector slots
    # ------------------------------------------------------------------

    @pyqtSlot(str)
    def select_speed(self, label: str) -> None:
        """QML slot: select playback speed by label ("Cham" / "Vua" / "Nhanh")."""
        try:
            self.speed_selector.select(label)
            logger.debug(f"Speed selected: {label} ({self.speed_selector.selected_fps} fps)")
        except ValueError as e:
            logger.warning(f"Invalid speed label: {e}")

    @pyqtSlot(result=str)
    def get_selected_speed_label(self) -> str:
        """Return the currently selected speed label."""
        return self.speed_selector.selected_label

    @pyqtSlot(result=int)
    def get_selected_fps(self) -> int:
        """Return the currently selected fps value."""
        return self.speed_selector.selected_fps

    @pyqtSlot(int, result=str)
    def get_suggested_speed(self, frame_count: int) -> str:
        """Return the auto-suggested speed label for *frame_count* (or '' if none)."""
        suggestion = self.speed_selector.get_suggested_label(frame_count)
        return suggestion or ""

    @pyqtSlot(result="QVariantList")
    def get_frame_paths(self) -> list[str]:
        """Return sorted list of absolute file:// paths for all current frames.

        Called by QML FilmStrip to refresh thumbnail sources after capture/delete.
        Uses a timestamp query-string suffix for cache-busting so QML Image
        does not show stale content after re-sequencing.
        """
        import time
        ts = int(time.time() * 1000)
        return [
            f"file://{p}?t={ts}"
            for p in self._session.frame_manager.get_all_frames()
        ]

    @pyqtSlot(int)
    def handle_delete_frame(self, n: int) -> None:
        """Public slot called from UI to delete frame at 1-based index n.

        Delegates to _do_delete_frame; errors are caught and surfaced via
        status_message so the UI can show a friendly alert without crashing.
        """
        self._do_delete_frame(n)

    @pyqtSlot(int)
    def delete_frame_smart(self, selected_index: int) -> None:
        """Delete logic: if selected_index > 0, delete that frame; otherwise delete last.

        selected_index is 1-based (0 means nothing selected).
        Called by keyboard Delete key handler in QML (T-011 AC1/AC7).
        """
        frame_count = self._session.frame_manager.frame_count
        if frame_count == 0:
            return
        if selected_index > 0 and selected_index <= frame_count:
            self._do_delete_frame(selected_index)
        else:
            # No selection → delete last frame
            self._do_delete_frame(frame_count)

    def _do_delete_frame(self, n: int) -> None:
        """Delete frame n (1-based), emit frame_deleted(new_count), log."""
        try:
            self._session.frame_manager.delete_frame(n)
        except ValueError as exc:
            logger.warning(f"delete_frame({n}) invalid: {exc}")
            self._bus.status_message.emit(
                "warning", f"Không thể xoá tấm {n}: {exc}"
            )
            return
        except OSError as exc:
            logger.error(f"delete_frame({n}) OS error: {exc}")
            self._bus.status_message.emit(
                "error", "Oi, xoá ảnh bị lỗi. Con thử lại nhé!"
            )
            return

        new_count = self._session.frame_manager.frame_count
        self._frame_count = new_count
        self.frameCountChanged.emit(new_count)
        self._bus.frame_deleted.emit(new_count)
        logger.info(f"handle_delete_frame({n}) — new count: {new_count}")

    @pyqtSlot()
    def reset_session(self) -> None:
        """Start a fresh session.

        Called from SuccessPage 'Quay lại' button OR auto-triggered when SHOOT
        arrives while we're on SuccessPage (post_export=True).
        """
        self._session.reset()
        self._capture.reset()
        self._frame_count = 0
        self._post_export = False
        # T-006: reset speed selector to default (Vua / 8fps) for new session
        self.speed_selector.reset()
        self.frameCountChanged.emit(0)
        self._bus.session_reset.emit()

    # ------------------------------------------------------------------
    # T-005: Camera picker slots
    # ------------------------------------------------------------------

    def _get_camera_selector(self) -> CameraSelector:
        """Lazy-create CameraSelector if not injected."""
        if self._camera_selector is None:
            self._camera_selector = CameraSelector(current_capture=self._capture)
        return self._camera_selector

    @pyqtSlot(int)
    def picker_probe_index(self, index: int) -> None:
        """QML slot: probe camera at *index*; emits cameraProbeResult(index, is_available).

        When probe succeeds, also bumps pickerCounter so QML refreshes the
        live-preview image from image://picker/<counter>.
        """
        sel = self._get_camera_selector()
        available = sel.probe_index(index)
        if available:
            self._picker_counter += 1
            self.pickerCounterChanged.emit(self._picker_counter)
        self.cameraProbeResult.emit(index, available)

    @pyqtSlot(int)
    def picker_confirm(self, new_index: int) -> None:
        """QML slot: confirm camera selection — switches engine, writes config."""
        sel = self._get_camera_selector()
        sel.confirm_selection(new_index)
        # Update internal reference so capture/preview keeps working
        self._capture = sel.get_current_capture()
        # Notify image provider update happens via webcam_ready signal in selector
        self.cameraChanged.emit(new_index)
        logger.info(f"Camera switched to index {new_index}")

    @pyqtSlot()
    def picker_cancel(self) -> None:
        """QML slot: cancel picker — restore old camera, release probed."""
        sel = self._get_camera_selector()
        sel.cancel_selection()

    @pyqtSlot(result=int)
    def get_current_webcam_index(self) -> int:
        """Return the currently active webcam index (for QML)."""
        return self._capture.webcam_index

    # ------------------------------------------------------------------
    # T-007: Save video / copy link slots
    # ------------------------------------------------------------------

    @pyqtSlot(str, str)
    def save_video(self, mp4_path: str, dest_dir: str) -> None:
        """QML slot: copy MP4 file to dest_dir.

        In production this runs on a Qt worker thread so the UI stays
        responsive.  Emits save_video_result(True, dest_path) on success,
        save_video_result(False, error_msg) on failure.
        """
        import threading
        saver = VideoSaver()

        def _run() -> None:
            saver.save(mp4_path, dest_dir)

        t = threading.Thread(target=_run, daemon=True)
        t.start()

    @pyqtSlot(str)
    def copy_link(self, url: str) -> None:
        """QML slot: copy share URL to clipboard."""
        VideoSaver().copy_link(url)

    @pyqtSlot(str)
    def open_save_dialog(self, mp4_path: str) -> None:
        """QML slot: open native folder picker dialog then copy MP4 to chosen dir.

        Runs QFileDialog on the main thread (required by Qt), then hands off
        the actual file copy to a background thread via save_video().
        If the user cancels the dialog, emits save_video_result(False, "")
        so the UI can reset the loading state.
        """
        from PyQt6.QtWidgets import QFileDialog
        dest_dir = QFileDialog.getExistingDirectory(
            None,
            "Chọn thư mục lưu phim",
            "",
        )
        if not dest_dir:
            # User cancelled — signal empty cancel so UI resets
            self._bus.save_video_result.emit(False, "__cancelled__")
            return
        self.save_video(mp4_path, dest_dir)

    # ------------------------------------------------------------------
    # T-012: Library service slots
    # ------------------------------------------------------------------

    @pyqtSlot(result="QVariantList")
    def library_list_sessions(self) -> list[object]:
        """QML slot: scan projects_dir and return session list as QVariantList.

        Returns list of dicts (QVariantMap) — each dict is a LibraryEntry.to_qml_dict().
        Returns empty list + logs error if projects_dir unreadable.
        """
        if self._library_service is None:
            logger.warning("library_list_sessions called but LibraryService not configured")
            return []
        try:
            entries = self._library_service.list_sessions()
            return [e.to_qml_dict() for e in entries]
        except OSError as e:
            logger.error(f"library_list_sessions failed: {e}")
            self._bus.status_message.emit("error", str(e))
            return []

    @pyqtSlot(str, result="bool")
    def library_delete_session(self, session_id: str) -> bool:
        """QML slot: delete session by id. Returns True on success, False on failure."""
        if self._library_service is None:
            logger.warning("library_delete_session called but LibraryService not configured")
            return False
        try:
            self._library_service.delete_session(session_id)
            logger.info(f"library_delete_session: deleted {session_id}")
            return True
        except (OSError, ValueError) as e:
            logger.error(f"library_delete_session failed for {session_id}: {e}")
            self._bus.status_message.emit("error", str(e))
            return False

    @pyqtSlot(str, str, str)
    def library_save_session(self, mp4_path: str, gif_path: str, qr_path: str) -> None:
        """QML slot: open save dialog and copy session files to chosen directory.

        Copies mp4 + gif (if exists) + qr (if exists) to user-chosen dir.
        Emits save_video_result on SignalBus.
        """
        from PyQt6.QtWidgets import QFileDialog
        dest_dir = QFileDialog.getExistingDirectory(
            None,
            "Chọn thư mục lưu phim",
            "",
        )
        if not dest_dir:
            self._bus.save_video_result.emit(False, "__cancelled__")
            return

        import shutil as _shutil
        import threading as _threading
        dest = Path(dest_dir)

        def _run() -> None:
            try:
                copied: list[str] = []
                for p in (mp4_path, gif_path, qr_path):
                    if p:
                        src = Path(p)
                        if src.exists():
                            _shutil.copy2(str(src), str(dest / src.name))
                            copied.append(src.name)
                msg = f"Đã lưu phim ra {dest}!"
                self._bus.save_video_result.emit(True, msg)
                logger.info(f"library_save_session: copied {copied} to {dest}")
            except PermissionError:
                self._bus.save_video_result.emit(
                    False, "Không đủ quyền lưu tại thư mục đó. Chọn thư mục khác nhé!"
                )
            except OSError as exc:
                self._bus.save_video_result.emit(False, f"Lưu không thành công: {exc}")

        _threading.Thread(target=_run, daemon=True).start()
