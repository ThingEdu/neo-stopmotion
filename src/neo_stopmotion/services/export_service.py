"""Async export wrapper — runs VideoExporter + cloud upload + QR on a QThread."""
from __future__ import annotations
import time
from PyQt6.QtCore import QObject, QThread, pyqtSignal
from loguru import logger

from neo_stopmotion.core.cloud_uploader import CloudUploader, UploadError, generate_qr
from neo_stopmotion.core.frame_manager import FrameManager
from neo_stopmotion.core.video_exporter import VideoExporter, ExportError
from neo_stopmotion.utils.signal_bus import SignalBus


class _ExportWorker(QObject):
    progress = pyqtSignal(float)
    completed = pyqtSignal(dict)
    failed = pyqtSignal(str)

    def __init__(
        self,
        fm: FrameManager,
        exporter: VideoExporter,
        uploader: CloudUploader | None = None,
    ) -> None:
        super().__init__()
        self.fm = fm
        self.exporter = exporter
        self.uploader = uploader

    def run(self) -> None:
        start = time.monotonic()
        try:
            self.progress.emit(0.05)
            mp4 = self.fm.session_dir / "output.mp4"
            self.exporter.export_mp4(self.fm.frames_dir, mp4)
            self.progress.emit(0.40)

            gif = self.fm.session_dir / "output.gif"
            self.exporter.export_gif(self.fm.frames_dir, gif)
            self.progress.emit(0.65)

            share_url = ""
            qr_path = ""
            if self.uploader is not None:
                try:
                    share_url = self.uploader.upload(mp4)
                    self.progress.emit(0.90)
                    qr_file = self.fm.session_dir / "qr.png"
                    generate_qr(share_url, qr_file)
                    qr_path = str(qr_file)
                except UploadError as e:
                    logger.warning(f"Cloud upload failed (non-fatal): {e}")

            elapsed = time.monotonic() - start
            self.fm.metadata.exported = True
            self.fm.metadata.mp4_path = mp4
            self.fm.metadata.gif_path = gif
            if share_url:
                self.fm.metadata.download_url = share_url
                self.fm.metadata.qr_path = self.fm.session_dir / "qr.png"
            self.fm._save_metadata()
            self.progress.emit(1.0)

            self.completed.emit({
                "mp4_path": str(mp4),
                "gif_path": str(gif),
                "share_url": share_url,
                "qr_path": qr_path,
                "elapsed_seconds": elapsed,
            })
        except ExportError as e:
            logger.error(f"Export failed: {e}")
            self.failed.emit(str(e))
        except Exception as e:
            logger.exception("Unexpected export error")
            self.failed.emit(str(e))


class ExportService(QObject):
    def __init__(
        self,
        exporter: VideoExporter,
        uploader: CloudUploader | None = None,
    ) -> None:
        super().__init__()
        self._exporter = exporter
        self._uploader = uploader
        self._bus = SignalBus.instance()
        self._thread: QThread | None = None
        self._worker: _ExportWorker | None = None

    def start_export(self, fm: FrameManager) -> None:
        if self._thread is not None and self._thread.isRunning():
            logger.warning("Export already in progress")
            return
        self._thread = QThread()
        self._worker = _ExportWorker(fm, self._exporter, self._uploader)
        self._worker.moveToThread(self._thread)
        self._thread.started.connect(self._worker.run)
        self._worker.progress.connect(self._bus.export_progress)
        self._worker.completed.connect(self._on_completed)
        self._worker.failed.connect(self._on_failed)
        self._bus.export_started.emit()
        self._thread.start()

    def _on_completed(self, payload: dict) -> None:
        self._bus.export_completed.emit(payload)
        self._cleanup()

    def _on_failed(self, msg: str) -> None:
        self._bus.export_failed.emit(msg)
        self._cleanup()

    def _cleanup(self) -> None:
        if self._thread is not None:
            self._thread.quit()
            self._thread.wait(2000)
        self._thread = None
        self._worker = None
