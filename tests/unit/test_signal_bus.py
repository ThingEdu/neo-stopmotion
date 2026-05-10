from neo_stopmotion.utils.signal_bus import SignalBus


def test_signal_bus_singleton():
    a = SignalBus.instance()
    b = SignalBus.instance()
    assert a is b


def test_signal_bus_uart_command_received(qtbot):
    bus = SignalBus.instance()
    received = []
    bus.uart_command_received.connect(lambda cmd: received.append(cmd))
    bus.uart_command_received.emit("SHOOT")
    assert received == ["SHOOT"]


def test_signal_bus_frame_captured(qtbot):
    bus = SignalBus.instance()
    received = []
    bus.frame_captured.connect(lambda n, p: received.append((n, p)))
    bus.frame_captured.emit(1, "/tmp/frame_0001.png")
    assert received == [(1, "/tmp/frame_0001.png")]
