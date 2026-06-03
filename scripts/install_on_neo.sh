#!/usr/bin/env bash
# ==============================================================================
# NeoStopMotion Installer
# First-time installation script for NeoStopMotion stop-motion studio.
# Handles ARM (Armbian/Raspberry Pi) and x86 platforms automatically.
#
# Usage:
#   Local:  bash scripts/install_on_neo.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/ThingEdu/neo-stopmotion/main/scripts/install_on_neo.sh | bash
#
# Options:
#   --no-desktop   Skip .desktop file and icon installation
#   --uninstall    Remove NeoStopMotion installation
# ==============================================================================
set -euo pipefail

# -- Configuration ------------------------------------------------------------
APP_NAME="neo-stopmotion"
DISPLAY_NAME="neo-stopmotion"
BIN_LINK="$HOME/.local/bin/neo-stopmotion"
DESKTOP_FILE="$HOME/.local/share/applications/neo-stopmotion.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/128x128/apps"
ICON_FILE="$ICON_DIR/neo-stopmotion.png"
PYPI_PACKAGE="neo-stopmotion"
PYTHON_MODULE="neo_stopmotion"
GITHUB_REPO="https://github.com/ThingEdu/neo-stopmotion.git"
RAW_INSTALL_URL="https://raw.githubusercontent.com/ThingEdu/neo-stopmotion/main/scripts/install_on_neo.sh"

# -- Parse arguments -----------------------------------------------------------
SKIP_DESKTOP=false
UNINSTALL=false

for arg in "$@"; do
    case "$arg" in
        --no-desktop) SKIP_DESKTOP=true ;;
        --uninstall)  UNINSTALL=true ;;
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

detect_arch() {
    local machine
    machine="$(uname -m)"
    case "$machine" in
        aarch64|armv7l|armv6l) echo "arm" ;;
        x86_64|i686|i386)     echo "x86" ;;
        *)                    echo "unknown" ;;
    esac
}

# pip install wrapper that adds --break-system-packages when needed.
pip_install() {
    local bsp=""
    if python3 -m pip install --help 2>&1 | grep -q "break-system-packages"; then
        bsp="--break-system-packages"
    fi
    python3 -m pip install $bsp "$@"
}

pip_uninstall() {
    local bsp=""
    if python3 -m pip install --help 2>&1 | grep -q "break-system-packages"; then
        bsp="--break-system-packages"
    fi
    python3 -m pip uninstall -y $bsp "$@" 2>/dev/null || true
}

python_has_pyqt6() {
    python3 - <<'PY' 2>/dev/null
from PyQt6.QtCore import QT_VERSION_STR
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtQuick import QQuickWindow
print(QT_VERSION_STR)
PY
}

python_has_opencv() {
    python3 - <<'PY' 2>/dev/null
import cv2
import numpy
print(cv2.__version__)
PY
}

# -- Uninstall -----------------------------------------------------------------
do_uninstall() {
    info "Uninstalling $DISPLAY_NAME..."

    pip_uninstall "$PYPI_PACKAGE"

    if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
        rm -f "$BIN_LINK"
        info "Removed symlink: $BIN_LINK"
    fi

    if [ -f "$DESKTOP_FILE" ]; then
        rm -f "$DESKTOP_FILE"
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        info "Removed desktop entry: $DESKTOP_FILE"
    fi

    if [ -f "$ICON_FILE" ]; then
        rm -f "$ICON_FILE"
        info "Removed icon: $ICON_FILE"
    fi

    info "$DISPLAY_NAME has been uninstalled."
    exit 0
}

if [ "$UNINSTALL" = true ]; then
    do_uninstall
fi

# -- Pre-flight checks ---------------------------------------------------------
ARCH="$(detect_arch)"
info "Detected architecture: $ARCH ($(uname -m))"

require_cmd python3

PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PYTHON_MAJOR="${PYTHON_VERSION%%.*}"
PYTHON_MINOR="${PYTHON_VERSION##*.}"

if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 10 ]; }; then
    error "Python 3.10+ is required (found $PYTHON_VERSION)."
    exit 1
fi
info "Python $PYTHON_VERSION found."

# -- Step 1: Install system dependencies --------------------------------------
install_system_deps() {
    if [ "$ARCH" = "arm" ]; then
        info "ARM detected - installing system binary dependencies..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            python3-pip \
            python3-numpy \
            python3-opencv \
            python3-pyqt6 \
            python3-pyqt6.qt \
            python3-pyqt6.qtquick \
            python3-pyqt6.qtmultimedia \
            python3-pyqt6.qtqml \
            git \
            ffmpeg \
            v4l-utils \
            libegl1 \
            libgl1 \
            libglib2.0-0 \
            libxkbcommon-x11-0 \
            libxcb-cursor0 \
            libxcb-xinerama0 \
            qt6-qpa-plugins \
            qt6-wayland \
            qml6-module-qtquick \
            qml6-module-qtquick-controls \
            qml6-module-qtquick-layouts \
            qml6-module-qtquick-window \
            qml6-module-qtquick-templates \
            qml6-module-qtqml-workerscript \
            qml6-module-qtmultimedia \
            2>/dev/null || true
    elif [ "$ARCH" = "x86" ]; then
        info "x86 detected - PyQt6 and OpenCV will be installed via pip."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq ffmpeg git python3-pip v4l-utils 2>/dev/null || true
        fi
    else
        warn "Unknown architecture '$(uname -m)'. Proceeding with pip-based install."
    fi
}

install_system_deps

# -- Step 2: Install package --------------------------------------------------
info "Installing $DISPLAY_NAME..."

if [ "$ARCH" = "arm" ]; then
    # ARM: avoid rebuilding PyQt6/OpenCV from source - use system apt packages.
    info "Installing Python dependencies excluding PyQt6, OpenCV, and numpy..."
    pip_install --quiet \
        "pyserial>=3.5" \
        "qrcode[pil]>=7.4" \
        "Pillow>=10.0.0" \
        "loguru>=0.7.0" \
        "tomli>=2.0.1; python_version<'3.11'"

    info "ARM detected - installing without Python package dependencies..."
    if ! pip_install --no-deps --quiet "$PYPI_PACKAGE" 2>&1; then
        info "PyPI install failed. Installing from GitHub source..."
        require_cmd git
        pip_install --no-deps "git+${GITHUB_REPO}"
    fi

    if ! python_has_pyqt6 >/dev/null; then
        error "PyQt6/QtQuick is not available from apt packages."
        error "Install the PyQt6 Qt/QML packages for this Armbian release, then rerun this script."
        exit 1
    fi

    if ! python_has_opencv >/dev/null; then
        error "OpenCV (cv2) is not available from apt packages."
        error "Install python3-opencv for this Armbian release, then rerun this script."
        exit 1
    fi
else
    # x86: PyQt6/OpenCV wheels are available, normal install.
    if pip_install --quiet "$PYPI_PACKAGE" 2>&1; then
        info "Installed from PyPI."
    else
        info "PyPI install failed. Installing from GitHub source..."
        require_cmd git
        pip_install "git+${GITHUB_REPO}"
    fi
fi

# -- Step 3: Verify installation ----------------------------------------------
# pip installs scripts to ~/.local/bin on Linux
NEO_BIN="$(python3 -c "
import sysconfig, os
scripts = sysconfig.get_path('scripts', 'posix_user')
print(os.path.join(scripts, 'neo-stopmotion'))
" 2>/dev/null || echo "$HOME/.local/bin/neo-stopmotion")"

if [ ! -f "$NEO_BIN" ]; then
    # Also check if it ended up on the system path
    NEO_BIN="$(command -v neo-stopmotion 2>/dev/null || true)"
fi

if [ -z "$NEO_BIN" ] || [ ! -f "$NEO_BIN" ]; then
    error "Installation failed - 'neo-stopmotion' binary not found."
    error "Check the output above for errors."
    exit 1
fi

# Ensure symlink in ~/.local/bin
mkdir -p "$(dirname "$BIN_LINK")"
if [ "$NEO_BIN" != "$BIN_LINK" ]; then
    ln -sf "$NEO_BIN" "$BIN_LINK"
fi
info "Verified: $NEO_BIN"

if ! command -v ffmpeg &>/dev/null; then
    error "ffmpeg is required but not found."
    exit 1
fi

# -- Step 4: Desktop integration ----------------------------------------------
install_desktop_entry() {
    if [ "$SKIP_DESKTOP" = true ]; then
        info "Skipping desktop integration (--no-desktop)."
        return
    fi

    local exec_path="$BIN_LINK"
    local icon_name="neo-stopmotion"

    # Try to find icon from installed package
    local pkg_icon
    pkg_icon="$(python3 -c "
import importlib.resources
try:
    ref = importlib.resources.files('neo_stopmotion') / 'resources' / 'images' / 'maker_viet_logo.png'
    with importlib.resources.as_file(ref) as p:
        print(p)
except Exception:
    pass
" 2>/dev/null || true)"

    if [ -n "$pkg_icon" ] && [ -f "$pkg_icon" ]; then
        mkdir -p "$ICON_DIR"
        cp "$pkg_icon" "$ICON_FILE"
        icon_name="$ICON_FILE"
        info "Installed icon: $ICON_FILE"
    fi

    mkdir -p "$(dirname "$DESKTOP_FILE")"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NEO Stopmotion
GenericName=Stop-motion Studio
Comment=Stop-motion studio for NEO One and ThingBot
Exec=$exec_path
Icon=$icon_name
Terminal=false
Categories=Education;Graphics;Video;
Keywords=stop-motion;animation;education;maker;thingbot;
StartupNotify=true
EOF

    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    info "Created desktop entry: $DESKTOP_FILE"
}

install_desktop_entry

# -- Step 5: Ensure ~/.local/bin is in PATH ------------------------------------
ensure_path() {
    local bin_dir="$HOME/.local/bin"
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "$bin_dir is not in your PATH."

        local shell_rc=""
        case "$(basename "${SHELL:-sh}")" in
            zsh)  shell_rc="$HOME/.zshrc" ;;
            bash) shell_rc="$HOME/.bashrc" ;;
            *)    shell_rc="$HOME/.profile" ;;
        esac

        if [ -f "$shell_rc" ] && ! grep -q 'local/bin' "$shell_rc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
            info "Added $bin_dir to PATH in $shell_rc"
            info "Run 'source $shell_rc' or open a new terminal to use 'neo-stopmotion'."
        fi
    fi
}

ensure_path

# -- Done ----------------------------------------------------------------------
echo ""
info "=========================================="
info "  $DISPLAY_NAME installed successfully!"
info "=========================================="
echo ""
echo "  Run:  neo-stopmotion"
echo ""
echo "  Uninstall:  curl -sSL $RAW_INSTALL_URL | bash -s -- --uninstall"
echo ""
