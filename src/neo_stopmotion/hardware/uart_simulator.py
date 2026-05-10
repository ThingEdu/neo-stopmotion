"""Drop-in UART replacement for dev — no serial port needed.

Useful when running on macOS without ThingBot connected. Commands are still
delivered via SignalBus.uart_command_received exactly as the real listener
would. Keyboard fallback in MainWindow.qml provides the input.
"""
from __future__ import annotations
from PyQt6.QtCore import QObject
from loguru import logger

from neo_stopmotion.hardware.uart_protocol import parse_line
from neo_stopmotion.utils.signal_bus import SignalBus


class UARTSimulator(QObject):
    """No-op UART backend; emits uart_reconnected on start."""

    def __init__(self) -> None:
        super().__init__()
        self._bus = SignalBus.instance()
        self._running = False

    def start(self) -> None:
        self._running = True
        logger.info(
            "UARTSimulator started — use Space/Z/Enter "
            "or call AppController.handle_uart_command() directly"
        )
        self._bus.uart_reconnected.emit()

    def stop(self) -> None:
        self._running = False

    def emit_command(self, cmd: str) -> None:
        if not self._running:
            return
        canonical = parse_line(cmd)
        if canonical is None:
            logger.warning(f"Sim ignoring invalid cmd: {cmd}")
            return
        self._bus.uart_command_received.emit(canonical)
