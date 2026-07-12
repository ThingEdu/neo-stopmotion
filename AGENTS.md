# AGENTS.md

This file provides guidance to AI AGENTS Code when working with code in this repository.

## Project

NeoStopMotion — a PyQt6/QML stop-motion animation app for kids (6–14), running on the NEO One education device (ARM64/Armbian) and Linux/macOS desktops. Kids capture frames with a physical ThingBot controller (2 buttons over UART), the app assembles MP4 + GIF via ffmpeg, uploads to catbox.moe, and shows a QR code for download. Published to PyPI as `neo-stopmotion`.

## Commands

```bash
make test        # pytest with coverage (all unit tests must pass)
make lint        # ruff check + mypy (strict mode)
make format      # ruff format + ruff check --fix
make run         # run app with real webcam
make run-sim     # NEO_STOPMOTION_UART=simulator python -m neo_stopmotion
make build       # python -m build
make deb         # bash scripts/build_deb.sh (Architecture: all .deb, built in a bookworm container via docker)
make publish     # bash scripts/publish.sh (PyPI via twine)
```

Single test file: `pytest tests/unit/test_frame_manager.py -v`
Single test: `pytest tests/unit/test_frame_manager.py::test_name -v`

Requires ffmpeg on PATH (app also probes Homebrew paths). Dev deps: `pip install -e . && pip install -r requirements-dev.txt`.

### Dev/test environment variables

| Variable | Effect |
|---|---|
| `NEO_STOPMOTION_CAPTURE=synthetic` | Test-pattern frames, no webcam needed |
| `NEO_STOPMOTION_UART=simulator` | No serial hardware; keyboard only |
| `NEO_STOPMOTION_CLOUD=0` | Disable cloud upload |
| `NEO_STOPMOTION_DEBUG=1` | DEBUG log level |
| `NEO_STOPMOTION_AUTOSHOOT=N` + `NEO_STOPMOTION_AUTOEXPORT=1` | Headless smoke test: fires N SHOOT commands, then EXPORT, then quits |

Keyboard fallback always works: `Space` = SHOOT, `Z` = UNDO, `Enter` = EXPORT.

## Architecture

Four layers, wired together in `src/neo_stopmotion/app.py` (`run()` is the composition root — read it first to see how everything connects):

1. **UI (QML)** — `ui/qml/`: `MainWindow.qml` holds a StackView (SplashScreen → CapturePage → ExportingPage → SuccessPage → reset). Singletons in `ui/qml/singletons/` (`NeoConstants.qml` design tokens, `AppState.qml` global state). QML talks to Python via two context properties: `appController` (calls into Python) and `signalBusBridge` (receives events).
2. **Services** — `services/`: `AppController` is the root QObject facade exposed to QML; it dispatches UART commands (SHOOT/UNDO/EXPORT). `SessionService` manages session lifecycle, `ExportService` wraps the exporter + uploader on a QThread.
3. **Core** — `core/`: `CaptureEngine` (cv2 webcam + onion skin), `SyntheticCaptureEngine` (drop-in fallback, auto-used when no webcam opens), `FrameManager` (atomic PNG writes + project.json), `VideoExporter` (ffmpeg subprocess, adds Maker Việt watermark), `CloudUploader` (catbox.moe primary, 0x0.st fallback).
4. **Hardware** — `hardware/`: `UARTListener` (pyserial + QThread, port auto-detect, 2s reconnect loop) and `UARTSimulator` (drop-in for dev), selected by `uart.port` config / `NEO_STOPMOTION_UART`.

### Key patterns

- **SignalBus** (`utils/signal_bus.py`): singleton pyqtSignal hub — modules communicate through it, never via direct references. New cross-module events go here. `_SignalBusBridge` in `app.py` re-exposes bus signals to QML (dict payloads flattened to plain args).
- **Worker threads**: all blocking I/O (cv2 reads, serial reads, ffmpeg, uploads) runs on QThreads — never on the main thread.
- **Live preview**: QML `Image` with `source: "image://preview/" + counter`, counter incremented by a ~30fps Timer to bust the cache; served by `PreviewImageProvider` → `CaptureEngine.get_live_preview()`.
- **Config**: `config/defaults.toml` → dataclasses in `config/settings.py`, overridable by user config and `NEO_STOPMOTION_*` env vars.

### Critical invariant

Onion skin exists **only** in the live preview. `CaptureEngine.get_live_preview()` blends the previous frame; `capture_frame()` must return/save the clean frame. Mixing these produces fake motion blur in the final film.

### Docs vs. reality

`DOC/ARCHITECTURE.md` is the original design doc (in Vietnamese) — good for rationale and data flows, but it has drifted: the local `ShareServer` (http.server + LAN QR) was replaced by `CloudUploader`, and several planned QML components (ThumbnailStrip, CountdownOverlay, etc.) don't exist. Trust the code in `src/` over the doc.

## Conventions

- ruff (line-length 100) + mypy `strict = true` — new code must be fully typed.
- Tests live in `tests/unit/`; `conftest.py` has an autouse fixture resetting the `SignalBus` singleton between tests, and a `tmp_projects_dir` fixture. Hardware/webcam/ffmpeg are mocked — tests run with no devices attached.
- `README.md` is Vietnamese (GitHub-facing); `README-en.md` is English (PyPI-facing, referenced in pyproject.toml). Keep both in sync when documenting user-facing changes.
- UI strings are Vietnamese, aimed at children — keep that tone.
- Version is bumped in `pyproject.toml`, `src/neo_stopmotion/__init__.py`, and `debian/changelog` together (see CHANGELOG.md). Note `config/defaults.toml` also has a `version` field that has drifted — don't treat it as authoritative.
