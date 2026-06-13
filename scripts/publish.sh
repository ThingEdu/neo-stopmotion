#!/usr/bin/env bash
# Publish neo-stopmotion to PyPI.
#
# Usage:
#   bash scripts/publish.sh              # TestPyPI → confirm → real PyPI
#   bash scripts/publish.sh --test-only  # Upload to TestPyPI only
#   bash scripts/publish.sh --skip-test  # Skip TestPyPI, go straight to real PyPI
#
# Authentication (twine reads these automatically):
#   export TWINE_USERNAME=__token__
#   export TWINE_PASSWORD=<your-pypi-api-token>
#
# Or configure ~/.pypirc:
#   [pypi]
#   username = __token__
#   password = <your-pypi-api-token>
#
#   [testpypi]
#   username = __token__
#   password = <your-testpypi-api-token>

set -euo pipefail

# ── Load .env.publish if present ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env.publish"
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    set -a; source "$ENV_FILE"; set +a
fi

# ── Flags ──────────────────────────────────────────────────────────────────────
SKIP_TEST=false
TEST_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --skip-test) SKIP_TEST=true ;;
        --test-only) TEST_ONLY=true ;;
        *) echo "Unknown flag: $arg" >&2; exit 1 ;;
    esac
done

# ── Helpers ────────────────────────────────────────────────────────────────────
log()  { echo "▶ $*"; }
ok()   { echo "✓ $*"; }
fail() { echo "✗ $*" >&2; exit 1; }

# ── Prerequisites ──────────────────────────────────────────────────────────────
log "Checking prerequisites..."
command -v python >/dev/null 2>&1  || fail "python not found — activate your virtualenv first."
command -v twine  >/dev/null 2>&1  || fail "twine not found — run: pip install twine"
python -m build --version          >/dev/null 2>&1 || fail "build not found — run: pip install build"
ok "Prerequisites OK"

# ── Read package version ───────────────────────────────────────────────────────
PKG_VERSION=$(python -c "
import sys, pathlib
p = pathlib.Path('pyproject.toml')
if sys.version_info >= (3, 11):
    import tomllib
    data = tomllib.loads(p.read_text())
else:
    import tomli
    data = tomli.loads(p.read_text())
print(data['project']['version'])
")
PKG_NAME="neo-stopmotion"
log "Package: ${PKG_NAME} v${PKG_VERSION}"

# ── Clean ──────────────────────────────────────────────────────────────────────
log "Cleaning previous build artifacts..."
rm -rf dist/ build/ src/*.egg-info
ok "Clean done"

# ── Build ──────────────────────────────────────────────────────────────────────
log "Building source distribution and wheel..."
python -m build
ok "Build done — artifacts in dist/:"
ls dist/

# ── Validate ───────────────────────────────────────────────────────────────────
log "Validating distribution metadata..."
twine check dist/*
ok "Metadata valid"

# ── TestPyPI ───────────────────────────────────────────────────────────────────
if [ "$SKIP_TEST" = false ]; then
    log "Uploading to TestPyPI..."
    _SAVED_PW="${TWINE_PASSWORD:-}"
    if [ -n "${TWINE_TEST_PASSWORD:-}" ]; then export TWINE_PASSWORD="$TWINE_TEST_PASSWORD"; fi
    twine upload --repository testpypi dist/*
    export TWINE_PASSWORD="$_SAVED_PW"
    echo ""
    ok "TestPyPI upload complete."
    echo "   View at: https://test.pypi.org/project/${PKG_NAME}/${PKG_VERSION}/"
    echo "   Install: pip install --index-url https://test.pypi.org/simple/ ${PKG_NAME}==${PKG_VERSION}"
    echo ""

    if [ "$TEST_ONLY" = true ]; then
        log "--test-only: stopping after TestPyPI upload."
        exit 0
    fi

    # Prompt before publishing to real PyPI
    read -r -p "Publish to real PyPI? [y/N] " CONFIRM
    case "$CONFIRM" in
        [yY][eE][sS]|[yY]) ;;
        *) log "Aborted — not publishing to real PyPI."; exit 0 ;;
    esac
fi

# ── Real PyPI ──────────────────────────────────────────────────────────────────
log "Uploading to PyPI..."
twine upload dist/*
echo ""
ok "PyPI upload complete."
echo "   View at: https://pypi.org/project/${PKG_NAME}/${PKG_VERSION}/"
echo "   Install: pip install ${PKG_NAME}==${PKG_VERSION}"
