"""SpeedSelector — T-006 video-speed feature.

Manages the 3-option speed selector (Cham / Vua / Nhanh) that controls
the FPS used for both MP4 and GIF export.

Spec ref:  docs/01-specs/features/video-speed/spec.md
Design:    docs/01-specs/features/video-speed/design-spec.md

PO-confirmed values (2026-06-15):
    Cham  = 5 fps
    Vua   = 8 fps   (default)
    Nhanh = 12 fps

Auto-suggestion logic (Q2b):
    0 frames     → None (disabled)
    1-15 frames  → "Cham"
    16-30 frames → "Vua"
    >30 frames   → "Nhanh"
"""
from __future__ import annotations

# Exported so tests can inspect
SPEED_OPTIONS: list[dict[str, str | int]] = [
    {"label": "Cham", "fps": 5, "icon": "\U0001F40C"},    # snail emoji
    {"label": "Vua",  "fps": 8, "icon": "\U0001F407"},    # rabbit emoji
    {"label": "Nhanh", "fps": 12, "icon": "⚡"},      # lightning emoji
]

_LABEL_TO_FPS: dict[str, int] = {
    str(opt["label"]): int(opt["fps"])
    for opt in SPEED_OPTIONS
}
_DEFAULT_LABEL = "Vua"


class SpeedSelector:
    """Holds the currently-selected playback speed for export.

    UI layer reads `selected_fps` and passes it to ExportService at export time.
    """

    def __init__(self) -> None:
        self._selected_label: str = _DEFAULT_LABEL
        # None = user has not manually chosen (suggestion may still show)
        self._user_chosen: bool = False

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------

    @property
    def selected_label(self) -> str:
        return self._selected_label

    @property
    def selected_fps(self) -> int:
        return _LABEL_TO_FPS[self._selected_label]

    @property
    def user_chosen(self) -> bool:
        """True if the user has explicitly selected a speed (not just default)."""
        return self._user_chosen

    def fps_for_label(self, label: str) -> int:
        """Return fps value for *label*, raise ValueError if unknown."""
        if label not in _LABEL_TO_FPS:
            raise ValueError(f"Unknown speed label: {label!r}")
        return _LABEL_TO_FPS[label]

    # ------------------------------------------------------------------
    # Write
    # ------------------------------------------------------------------

    def select(self, label: str) -> None:
        """Manually select a speed by label ("Cham" / "Vua" / "Nhanh").

        Raises ValueError for unknown labels.
        """
        if label not in _LABEL_TO_FPS:
            raise ValueError(f"Unknown speed label: {label!r}. Valid: {list(_LABEL_TO_FPS)}")
        self._selected_label = label
        self._user_chosen = True

    def reset(self) -> None:
        """Reset to default (Vua / 8fps) — called on session reset."""
        self._selected_label = _DEFAULT_LABEL
        self._user_chosen = False

    # ------------------------------------------------------------------
    # Auto-suggestion (spec §"Gợi ý tự động")
    # ------------------------------------------------------------------

    def get_suggested_label(self, frame_count: int) -> str | None:
        """Return suggested speed label based on current frame count.

        Returns None when frame_count == 0 (selector should be disabled).
        Does NOT override the user's manual selection; callers decide whether
        to apply the suggestion.
        """
        if frame_count == 0:
            return None
        if frame_count <= 15:
            return "Cham"
        if frame_count <= 30:
            return "Vua"
        return "Nhanh"
