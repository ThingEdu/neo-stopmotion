from neo_stopmotion.hardware.uart_protocol import VALID_COMMANDS, parse_line


def test_parse_valid_commands():
    for cmd in VALID_COMMANDS:
        assert parse_line(cmd) == cmd
        assert parse_line(cmd + "\n") == cmd
        assert parse_line(cmd + "\r\n") == cmd
        assert parse_line("  " + cmd + "  ") == cmd
        assert parse_line(cmd.lower()) == cmd  # case-insensitive


def test_parse_invalid_returns_none():
    assert parse_line("FOO") is None
    assert parse_line("") is None
    assert parse_line("   ") is None
    assert parse_line(None) is None
