"""UART listener — auto-detect ThingBot serial port + reconnect on disconnect."""
from __future__ import annotations
import glob
import time

import serial
from PyQt6.QtCore import QObject, QThread, QTimer, pyqtSignal
from loguru import logger

from neo_stopmotion.hardware.uart_protocol import parse_line
from neo_stopmotion.utils.signal_bus import SignalBus


COMMON_PORTS: tuple[str, ...] = (
    "/dev/ttyUSB0", "/dev/ttyUSB1",
    "/dev/ttyACM0", "/dev/ttyACM1",
)


def candidate_ports() -> list[str]:
    """Return all likely ThingBot serial ports on this system."""
    found = list(COMMON_PORTS)
    found.extend(glob.glob("/dev/tty.usbserial*"))
    found.extend(glob.glob("/dev/tty.usbmodem*"))
    found.extend(glob.glob("/dev/cu.usbmodem*"))
    found.extend(glob.glob("/dev/cu.usbserial*"))
    found.extend(glob.glob("/dev/thingbot"))  # udev-managed symlink
    return found


def auto_detect_port(baudrate: int = 115200, timeout: float = 2.5) -> str | None:
    """Probe candidate ports; return the first that emits READY."""
    for port in candidate_ports():
        try:
            s = serial.Serial(port, baudrate, timeout=timeout)
            line = s.readline().decode(errors="ignore").strip()
            s.close()
            if line == "READY":
                logger.info(f"ThingBot detected on {port}")
                return port
        except (serial.SerialException, OSError, UnicodeDecodeError):
            continue
    return None


class _UARTWorker(QObject):
    line_received = pyqtSignal(str)
    disconnected = pyqtSignal()

    def __init__(self, port: str, baudrate: int) -> None:
        super().__init__()
        self.port = port
        self.baudrate = baudrate
        self._running = False
        self._serial: serial.Serial | None = None

    def stop(self) -> None:
        self._running = False
        if self._serial is not None:
            try:
                self._serial.close()
            except Exception:
                pass

    def run(self) -> None:
        try:
            self._serial = serial.Serial(self.port, self.baudrate, timeout=1.0)
        except serial.SerialException as e:
            logger.error(f"Serial open failed on {self.port}: {e}")
            self.disconnected.emit()
            return
        self._running = True
        logger.info(f"UART listening on {self.port} @ {self.baudrate}")
        while self._running:
            try:
                raw = self._serial.readline()
                if not raw:
                    continue
                self.line_received.emit(raw.decode(errors="ignore"))
            except (serial.SerialException, OSError) as e:
                logger.warning(f"Serial read error: {e}")
                self.disconnected.emit()
                break


class UARTListener(QObject):
    """Listen to ThingBot UART and route commands to SignalBus.

    Auto-detect port on start. Reconnect every `reconnect_interval_seconds` if
    the worker reports disconnect. Defensive 200ms debounce on SHOOT in addition
    to firmware's 50ms.
    """

    def __init__(
        self,
        port: str | None = None,
        baudrate: int = 115200,
        reconnect_interval_seconds: int = 2,
        debounce_ms: int = 200,
    ) -> None:
        super().__init__()
        self.port = port
        self.baudrate = baudrate
        self.reconnect_interval_seconds = reconnect_interval_seconds
        self.debounce_ms = debounce_ms
        self._bus = SignalBus.instance()
        self._thread: QThread | None = None
        self._worker: _UARTWorker | None = None
        self._last_emit_ms = 0.0
        self._reconnect_timer = QTimer()
        self._reconnect_timer.setInterval(reconnect_interval_seconds * 1000)
        self._reconnect_timer.timeout.connect(self._try_reconnect)

    def start(self) -> None:
        if self.port in (None, "auto"):
            self.port = auto_detect_port(self.baudrate)
        if self.port is None:
            logger.warning("No ThingBot detected — keyboard fallback only")
            self._bus.uart_disconnected.emit()
            self._reconnect_timer.start()
            return
        self._spawn_worker()

    def _spawn_worker(self) -> None:
        self._thread = QThread()
        self._worker = _UARTWorker(self.port, self.baudrate)
        self._worker.moveToThread(self._thread)
        self._thread.started.connect(self._worker.run)
        self._worker.line_received.connect(self._on_line)
        self._worker.disconnected.connect(self._on_disconnect)
        self._thread.start()
        self._bus.uart_reconnected.emit()

    def _on_line(self, line: str) -> None:
        cmd = parse_line(line)
        if cmd is None:
            return
        now = time.monotonic() * 1000.0
        if cmd == "SHOOT" and (now - self._last_emit_ms) < self.debounce_ms:
            return
        self._last_emit_ms = now
        self._bus.uart_command_received.emit(cmd)

    def _on_disconnect(self) -> None:
        self._bus.uart_disconnected.emit()
        if self._worker is not None:
            self._worker.stop()
        self._reconnect_timer.start()

    def _try_reconnect(self) -> None:
        port = auto_detect_port(self.baudrate)
        if port is None:
            return
        self.port = port
        self._reconnect_timer.stop()
        self._spawn_worker()
        logger.info(f"UART reconnected on {port}")

    def stop(self) -> None:
        self._reconnect_timer.stop()
        if self._worker is not None:
            self._worker.stop()
        if self._thread is not None:
            self._thread.quit()
            self._thread.wait(2000)
        self._worker = None
        self._thread = None
