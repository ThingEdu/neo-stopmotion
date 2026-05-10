"""ThingBot UART protocol: ASCII commands + newline."""
from __future__ import annotations

VALID_COMMANDS = frozenset({"SHOOT", "UNDO", "EXPORT", "READY", "BAT_LOW"})


def parse_line(line: str | None) -> str | None:
    """Strip whitespace, uppercase, validate. Returns canonical command or None."""
    if line is None:
        return None
    cleaned = line.strip().upper()
    if cleaned in VALID_COMMANDS:
        return cleaned
    return None
