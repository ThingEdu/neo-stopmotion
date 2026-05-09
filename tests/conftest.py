import sys
from pathlib import Path

import pytest

# Make src importable for tests
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))


@pytest.fixture(autouse=True)
def reset_signal_bus():
    """Reset SignalBus singleton between tests."""
    from neo_stopmotion.utils.signal_bus import SignalBus
    SignalBus._instance = None
    yield
    SignalBus._instance = None


@pytest.fixture
def tmp_projects_dir(tmp_path, monkeypatch):
    d = tmp_path / "projects"
    d.mkdir()
    monkeypatch.setenv("NEO_STOPMOTION_PROJECTS_DIR", str(d))
    return d
