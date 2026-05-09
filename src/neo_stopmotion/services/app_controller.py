from __future__ import annotations
from PyQt6.QtCore import QObject, pyqtSlot, pyqtProperty, pyqtSignal
from loguru import logger

from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError
from neo_stopmotion.services.session_service import SessionService
from neo_stopmotion.utils.signal_bus import SignalBus


class AppController(QObject):
    """Root QObject exposed to QML — facade over capture+session."""

    frameCountChanged = pyqtSignal(int)

    def __init__(self, capture: CaptureEngine, session: SessionService) -> None:
        super().__init__()
        self._capture = capture
        self._session = session
        self._bus = SignalBus.instance()
        self._frame_count = 0
        self._bus.uart_command_received.connect(self.handle_uart_command)

    @pyqtProperty(int, notify=frameCountChanged)
    def frameCount(self) -> int:
        return self._frame_count

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
        # Reload the new "last frame" so onion skin uses the correct source
        new_count = self._session.frame_manager.frame_count
        prev = self._session.frame_manager.load_frame(new_count) if new_count > 0 else None
        self._capture.set_last_frame(prev)
        self._frame_count = new_count
        self.frameCountChanged.emit(self._frame_count)
        self._bus.frame_undone.emit(new_count)

    def _do_export(self) -> None:
        # Filled in T4.3
        logger.info("Export requested (stub)")
        self._bus.export_started.emit()
