#!/usr/bin/env bash
# ==============================================================================
# NeoStopMotion Installer
# Installs the NeoStopMotion .deb package from GitHub Releases.
# Works on any apt-based system (Armbian/Debian/Ubuntu), arm64 and x86:
# the package is Architecture: all — apt pulls the right binary dependencies
# (PyQt6, OpenCV, ffmpeg, Qt6 QML) for each architecture.
#
# Usage:
#   Local:  bash scripts/install_on_neo.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-stopmotion/main/scripts/install_on_neo.sh | bash
#
# Options:
#   --uninstall        Remove NeoStopMotion installation
#   --version=X.Y.Z    Install a specific release (default: latest)
# ==============================================================================
set -euo pipefail

# -- Configuration ------------------------------------------------------------
REPO="ThingEdu/neo-stopmotion"
PKG="neo-stopmotion"
RAW_INSTALL_URL="https://raw.githubusercontent.com/${REPO}/main/scripts/install_on_neo.sh"

# -- Parse arguments -----------------------------------------------------------
UNINSTALL=false
INSTALL_VERSION=""

for arg in "$@"; do
    case "$arg" in
        --uninstall)  UNINSTALL=true ;;
        --version=*)  INSTALL_VERSION="${arg#*=}"; INSTALL_VERSION="${INSTALL_VERSION#v}" ;;
        --no-desktop) echo "[WARN] --no-desktop is deprecated (desktop entry now ships in the .deb)." ;;
        *)            echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# -- Helpers -------------------------------------------------------------------
info()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        error "'$1' is required but not found. Please install it first."
        exit 1
    fi
}

SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
fi

# pip uninstall wrapper for cleaning up legacy (pre-.deb) installations.
pip_uninstall() {
    local bsp=""
    if python3 -m pip install --help 2>&1 | grep -q "break-system-packages"; then
        bsp="--break-system-packages"
    fi
    python3 -m pip uninstall -y $bsp "$@" 2>/dev/null || true
}

# Remove artifacts left by the old pip-based installer, which would otherwise
# shadow the system package (~/.local/bin comes first in PATH).
cleanup_legacy_pip_install() {
    if command -v python3 &>/dev/null \
        && python3 -m pip show "$PKG" &>/dev/null; then
        info "Removing legacy pip installation..."
        pip_uninstall "$PKG"
    fi
    rm -f "$HOME/.local/bin/neo-stopmotion"
    if [ -f "$HOME/.local/share/applications/neo-stopmotion.desktop" ]; then
        rm -f "$HOME/.local/share/applications/neo-stopmotion.desktop"
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    rm -f "$HOME/.local/share/icons/hicolor/128x128/apps/neo-stopmotion.png"
}

# -- Uninstall -----------------------------------------------------------------
if [ "$UNINSTALL" = true ]; then
    info "Uninstalling $PKG..."
    if command -v apt-get &>/dev/null && dpkg -s "$PKG" &>/dev/null; then
        $SUDO apt-get remove -y "$PKG"
    fi
    cleanup_legacy_pip_install
    info "$PKG has been uninstalled."
    exit 0
fi

# -- Pre-flight checks ---------------------------------------------------------
info "Detected architecture: $(uname -m)"

if ! command -v apt-get &>/dev/null; then
    error "This installer requires an apt-based system (Armbian/Debian/Ubuntu)."
    error "On other systems, install from PyPI instead: pip install $PKG"
    exit 1
fi
require_cmd curl

# -- Step 1: Resolve version ----------------------------------------------------
if [ -z "$INSTALL_VERSION" ]; then
    info "Resolving latest release..."
    INSTALL_VERSION="$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')"
    if [ -z "$INSTALL_VERSION" ]; then
        error "Could not determine the latest release. Check your network,"
        error "or pin a version: bash install_on_neo.sh --version=X.Y.Z"
        exit 1
    fi
fi
info "Installing $PKG $INSTALL_VERSION"

DEB_NAME="${PKG}_${INSTALL_VERSION}_all.deb"
DEB_URL="https://github.com/${REPO}/releases/download/v${INSTALL_VERSION}/${DEB_NAME}"

# -- Step 2: Download and install ------------------------------------------------
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

info "Downloading $DEB_URL"
if ! curl -fSL --progress-bar -o "$TMP_DIR/$DEB_NAME" "$DEB_URL"; then
    error "Download failed. Does release v${INSTALL_VERSION} exist and include ${DEB_NAME}?"
    error "See: https://github.com/${REPO}/releases"
    exit 1
fi

info "Installing via apt (pulls PyQt6, OpenCV, ffmpeg, Qt6 QML from apt)..."
$SUDO apt-get update -qq || true
$SUDO apt-get install -y "$TMP_DIR/$DEB_NAME"

# -- Step 3: Clean up legacy pip install and verify ------------------------------
cleanup_legacy_pip_install

if ! command -v neo-stopmotion &>/dev/null; then
    error "Installation failed - 'neo-stopmotion' not found on PATH."
    exit 1
fi
info "Verified: $(command -v neo-stopmotion)"

# -- Done ----------------------------------------------------------------------
echo ""
info "=========================================="
info "  $PKG $INSTALL_VERSION installed successfully!"
info "=========================================="
echo ""
echo "  Run:  neo-stopmotion"
echo ""
echo "  Uninstall:  curl -sSL $RAW_INSTALL_URL | bash -s -- --uninstall"
echo ""
