from __future__ import annotations
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

if sys.version_info >= (3, 11):
    import tomllib
else:
    import tomli as tomllib


DEFAULTS_PATH = Path(__file__).parent / "defaults.toml"


@dataclass
class AppCfg:
    name: str = "NeoStopMotion"
    version: str = "1.0.0"
    language: str = "vi"
    debug: bool = False


@dataclass
class CaptureCfg:
    webcam_index: int = 0
    resolution_width: int = 1280
    resolution_height: int = 720
    preview_fps: int = 30
    onion_opacity: float = 0.30
    auto_retry_count: int = 3


@dataclass
class UartCfg:
    port: str = "auto"
    baudrate: int = 115200
    reconnect_interval_seconds: int = 2
    keyboard_fallback: bool = True


@dataclass
class ExportCfg:
    playback_fps: int = 10
    min_frames: int = 5
    max_frames: int = 100
    mp4_codec: str = "libx264"
    mp4_pix_fmt: str = "yuv420p"
    gif_scale_width: int = 640
    ffmpeg_binary: str = "ffmpeg"


@dataclass
class StorageCfg:
    projects_dir: str = "~/projects"
    max_sessions: int = 50
    auto_cleanup_threshold_mb: int = 100


@dataclass
class ServerCfg:
    http_port: int = 8000
    qr_size: int = 400


@dataclass
class UiCfg:
    fullscreen: bool = False
    window_width: int = 1920
    window_height: int = 1080
    font_family: str = "Be Vietnam Pro"
    sound_enabled: bool = True
    flash_on_capture: bool = True
    show_countdown: bool = True
    show_thumbnail_strip: bool = True
    ask_title_before_export: bool = True


@dataclass
class AppSettings:
    app: AppCfg = field(default_factory=AppCfg)
    capture: CaptureCfg = field(default_factory=CaptureCfg)
    uart: UartCfg = field(default_factory=UartCfg)
    export: ExportCfg = field(default_factory=ExportCfg)
    storage: StorageCfg = field(default_factory=StorageCfg)
    server: ServerCfg = field(default_factory=ServerCfg)
    ui: UiCfg = field(default_factory=UiCfg)


def _read_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as f:
        return tomllib.load(f)


def _merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    out = dict(base)
    for k, v in override.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


_ENV_MAP = {
    "NEO_STOPMOTION_UART_PORT": ("uart", "port"),
    "NEO_STOPMOTION_UART": ("uart", "port"),
    "NEO_STOPMOTION_WEBCAM_INDEX": ("capture", "webcam_index", int),
    "NEO_STOPMOTION_DEBUG": ("app", "debug", lambda s: s.lower() in ("1", "true", "yes")),
    "NEO_STOPMOTION_PROJECTS_DIR": ("storage", "projects_dir"),
}


def _apply_env(data: dict[str, Any]) -> dict[str, Any]:
    for env, target in _ENV_MAP.items():
        if env not in os.environ:
            continue
        section, key, *rest = target
        cast = rest[0] if rest else str
        data.setdefault(section, {})[key] = cast(os.environ[env])
    return data


def load_settings(user_config_path: Path | None = None) -> AppSettings:
    data = _read_toml(DEFAULTS_PATH)
    if user_config_path is not None and user_config_path.exists():
        data = _merge(data, _read_toml(user_config_path))
    elif user_config_path is None:
        default_user = Path.home() / ".config" / "neostopmotion" / "config.toml"
        if default_user.exists():
            data = _merge(data, _read_toml(default_user))
    data = _apply_env(data)
    return AppSettings(
        app=AppCfg(**data.get("app", {})),
        capture=CaptureCfg(**data.get("capture", {})),
        uart=UartCfg(**data.get("uart", {})),
        export=ExportCfg(**data.get("export", {})),
        storage=StorageCfg(**data.get("storage", {})),
        server=ServerCfg(**data.get("server", {})),
        ui=UiCfg(**data.get("ui", {})),
    )
