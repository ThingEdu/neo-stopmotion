"""CameraSelector service — T-005 camera-select.

Allows Tho Ca to cycle through webcam indices 0-5, see live preview,
and confirm selection.  Persists choice to user config TOML.

Spec ref: docs/01-specs/features/camera-select/spec.md
Design:   docs/01-specs/features/camera-select/design-spec.md
"""
from __future__ import annotations

import sys
from pathlib import Path
from typing import TYPE_CHECKING

from loguru import logger

if TYPE_CHECKING:
    from neo_stopmotion.core.capture_engine import CaptureEngine

if sys.version_info >= (3, 11):
    import tomllib
else:
    import tomli as tomllib

# Number of camera indices to probe (0..MAX_INDEX-1)
MAX_INDEX = 6
_DEFAULT_CONFIG_PATH = Path.home() / ".config" / "neostopmotion" / "config.toml"


class CameraSelector:
    """Cycle through webcam indices 0-5 with live probe.

    Usage::

        selector = CameraSelector(current_capture=engine)
        available = selector.probe_index(1)
        if available:
            selector.confirm_selection(1)
        else:
            selector.cancel_selection()
    """

    def __init__(
        self,
        current_capture: CaptureEngine,
        config_path: Path | None = None,
    ) -> None:
        self._current_capture: CaptureEngine = current_capture
        self._config_path: Path = config_path or _DEFAULT_CONFIG_PATH
        self._probed_cap: CaptureEngine | None = None
        self._probed_index: int | None = None

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    @property
    def selected_index(self) -> int:
        """Return the currently active webcam index (0 if engine has none, e.g. synthetic)."""
        return getattr(self._current_capture, "webcam_index", 0)

    @staticmethod
    def next_index(current: int) -> int:
        """Return next index (wraps 5 → 0)."""
        return (current + 1) % MAX_INDEX

    @staticmethod
    def prev_index(current: int) -> int:
        """Return previous index (wraps 0 → 5)."""
        return (current - 1) % MAX_INDEX

    def probe_index(self, index: int) -> bool:
        """Try to open camera at *index*.

        Releases any previously probed camera first.
        Returns True if camera is opened successfully.
        """
        self._release_probed()
        cap, ok = self._try_open_index(index)
        if ok and cap is not None:
            self._probed_cap = cap
            self._probed_index = index
        else:
            self._probed_cap = None
            self._probed_index = index  # keep track even if failed
        return ok

    def probe_any(self) -> bool:
        """Probe indices 0-5 in order, return True if any is available."""
        for idx in range(MAX_INDEX):
            if self.probe_index(idx):
                return True
        return False

    def list_available_indices(self) -> list[int]:
        """Return a list of working camera indices (0..MAX_INDEX-1).

        Probes each index quickly (retry_delay_seconds=0) so the full scan
        completes in under 1 second even on slow hardware.  Releases every
        tested camera immediately; does NOT store state in self._probed_cap.

        Returns an empty list when no camera is found.
        """
        available: list[int] = []
        for idx in range(MAX_INDEX):
            cap, ok = self._try_open_fast(idx)
            if ok:
                available.append(idx)
            if cap is not None:
                try:
                    cap.release()
                except Exception:  # noqa: BLE001
                    pass
        logger.debug(f"list_available_indices → {available}")
        return available

    def _try_open_fast(self, index: int) -> tuple[CaptureEngine | None, bool]:
        """Like _try_open_index but with retry_delay_seconds=0 for fast enumeration."""
        from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError

        cap = CaptureEngine(webcam_index=index, retry_count=1, retry_delay_seconds=0.0)
        try:
            cap.open()
            if not cap.is_open:
                return None, False
            return cap, True
        except CaptureError as e:
            logger.debug(f"Fast probe index {index} unavailable: {e}")
            try:
                cap.release()
            except Exception:  # noqa: BLE001
                pass
            return None, False

    def get_probed_preview(self) -> object:
        """Return a live preview frame (numpy array) from the probed camera, or None."""
        if self._probed_cap is None:
            return None
        return self._probed_cap.get_live_preview()

    def confirm_selection(self, new_index: int) -> None:
        """Apply the probed camera as the active capture engine.

        Releases the old capture engine and replaces it with the probed one,
        emits ``webcam_ready``, and writes config.

        Note: Callers in app.py must also update ``PreviewImageProvider`` to
        point to the new CaptureEngine instance.
        """
        from neo_stopmotion.utils.signal_bus import SignalBus

        # Release the old capture engine
        try:
            self._current_capture.release()
        except Exception:  # noqa: BLE001
            pass

        if self._probed_cap is not None:
            # Use the already-open probed engine
            self._current_capture = self._probed_cap
            self._probed_cap = None
        else:
            # Probed cap not stored (e.g. cancel path won't reach here),
            # open a fresh one for new_index
            cap, _ = self._try_open_index(new_index)
            if cap is not None:
                self._current_capture = cap

        self._write_config(webcam_index=new_index)
        SignalBus.instance().webcam_ready.emit()
        logger.info(f"Camera selected: index={new_index}")

    def cancel_selection(self) -> None:
        """Discard the probed camera; keep the existing capture engine."""
        self._release_probed()
        logger.info(
            "Camera selection cancelled — keeping index=%d",
            getattr(self._current_capture, "webcam_index", 0),
        )

    def get_current_capture(self) -> CaptureEngine:
        """Return the active CaptureEngine (may have changed after confirm)."""
        return self._current_capture

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _release_probed(self) -> None:
        if self._probed_cap is not None:
            try:
                self._probed_cap.release()
            except Exception:  # noqa: BLE001
                pass
            self._probed_cap = None

    def _try_open_index(self, index: int) -> tuple[CaptureEngine | None, bool]:
        """Attempt to open a new CaptureEngine at *index*.

        Returns (engine, True) on success, (None, False) on failure.
        """
        from neo_stopmotion.core.capture_engine import CaptureEngine, CaptureError

        cap = CaptureEngine(webcam_index=index, retry_count=1)
        try:
            cap.open()
            if not cap.is_open:
                return None, False
            return cap, True
        except CaptureError as e:
            logger.debug(f"Camera index {index} unavailable: {e}")
            try:
                cap.release()
            except Exception:  # noqa: BLE001
                pass
            return None, False

    def _write_config(self, webcam_index: int) -> None:
        """Write (or merge) [capture] webcam_index = N into the user config TOML."""
        # Read existing config if present
        existing: dict[str, dict[str, object]] = {}
        if self._config_path.exists():
            try:
                with self._config_path.open("rb") as f:
                    raw = tomllib.load(f)
                    existing = {k: v for k, v in raw.items() if isinstance(v, dict)}
            except Exception as e:  # noqa: BLE001
                logger.warning(f"Could not read existing config for merge: {e}")

        # Merge in the new webcam_index
        capture_section: dict[str, object] = dict(existing.get("capture", {}))
        capture_section["webcam_index"] = webcam_index
        existing["capture"] = capture_section

        # Serialise back to TOML manually (tomllib is read-only; avoid dep on tomli-w)
        try:
            self._config_path.parent.mkdir(parents=True, exist_ok=True)
            lines: list[str] = []
            for section, values in existing.items():
                if isinstance(values, dict):
                    lines.append(f"[{section}]")
                    for k, v in values.items():
                        if isinstance(v, str):
                            lines.append(f'{k} = "{v}"')
                        elif isinstance(v, bool):
                            lines.append(f"{k} = {'true' if v else 'false'}")
                        else:
                            lines.append(f"{k} = {v}")
                    lines.append("")
            self._config_path.write_text("\n".join(lines))
            logger.info(f"Saved webcam_index={webcam_index} to {self._config_path}")
        except OSError as e:
            # Non-fatal: camera still works in current session
            logger.warning(f"Could not save webcam_index to config: {e}")
