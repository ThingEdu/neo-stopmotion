#!/usr/bin/env bash
# ==============================================================================
# NeoStopMotion Installer
# First-time installation script for the NeoStopMotion stop-motion studio.
# Handles ARM (Armbian/Raspberry Pi) and x86 platforms automatically.
#
# Usage:
#   Local:  bash scripts/install_on_neo.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/makerviet/NeoStopMotion/main/scripts/install_on_neo.sh | bash
#
# Options:
#   --no-desktop   Skip .desktop file and icon installation
#   --uninstall    Remove NeoStopMotion installation
# ==============================================================================
set -euo pipefail

# -- Configuration ------------------------------------------------------------
APP_NAME="neo-stopmotion"
DISPLAY_NAME="NeoStopMotion"
BIN_NAME="neo-stopmotion"
BIN_LINK="$HOME/.local/bin/$BIN_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/128x128/apps"
ICON_FILE="$ICON_DIR/$APP_NAME.png"
PYPI_PACKAGE="neo-stopmotion"
PYTHON_MODULE="neo_stopmotion"
GITHUB_REPO="https://github.com/makerviet/NeoStopMotion.git"
RAW_INSTALL_URL="https://raw.githubusercontent.com/makerviet/NeoStopMotion/main/scripts/install_on_neo.sh"

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

has_apt() {
    command -v apt-get &>/dev/null
}

apt_install_required() {
    if ! has_apt; then
        warn "apt-get not found. Skipping system dependency installation."
        return
    fi

    sudo apt-get update -qq
    sudo apt-get install -y -qq "$@"
}

apt_install_optional() {
    if ! has_apt; then
        return
    fi

    local missing=()
    local package
    for package in "$@"; do
        if ! sudo apt-get install -y -qq "$package" 2>/dev/null; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        warn "Some optional apt packages were not available: ${missing[*]}"
    fi
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

pip_install_binary_only() {
    pip_install --only-binary=:all: "$@"
}

python_has_pyqt6() {
    python3 - <<'PY' 2>/dev/null
from PyQt6.QtCore import QT_VERSION_STR
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtQuick import QQuickWindow
print(QT_VERSION_STR)
PY
}

# -- Uninstall -----------------------------------------------------------------
do_uninstall() {
    info "Uninstalling $DISPLAY_NAME..."

    pip_uninstall "$PYPI_PACKAGE"

    if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
        rm -f "$BIN_LINK"
        info "Removed launcher: $BIN_LINK"
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
    if ! has_apt; then
        warn "Non-apt system detected. Please install ffmpeg and Qt runtime packages manually."
        return
    fi

    info "Installing base system dependencies..."
    apt_install_required \
        python3-pip \
        git \
        ffmpeg \
        v4l-utils \
        libegl1 \
        libgl1 \
        libglib2.0-0 \
        libxkbcommon-x11-0 \
        libxcb-cursor0 \
        libxcb-xinerama0

    info "Installing Qt6/PyQt6 binary packages when available..."
    apt_install_optional \
        python3-pyqt6 \
        python3-pyqt6.qtquick \
        python3-pyqt6.qtmultimedia \
        python3-pyqt6.qtqml \
        qt6-base-dev \
        qt6-qpa-plugins \
        qt6-wayland \
        qml6-module-qtquick \
        qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts \
        qml6-module-qtquick-window \
        qml6-module-qtquick-templates \
        qml6-module-qtquick-templates2 \
        qml6-module-qtqml \
        qml6-module-qtqml-workerscript \
        qml6-module-qtmultimedia
}

install_system_deps

# -- Step 2: Install Python dependencies --------------------------------------
install_python_deps() {
    info "Upgrading Python packaging tools..."
    pip_install --user --upgrade pip setuptools wheel

    if [ "$ARCH" = "arm" ]; then
        info "ARM detected. Avoiding Qt source builds."
        info "Installing non-Qt Python dependencies..."
        pip_install --user --prefer-binary \
            "opencv-python-headless>=4.8.0" \
            "numpy>=1.24.0" \
            "pyserial>=3.5" \
            "qrcode[pil]>=7.4" \
            "Pillow>=10.0.0" \
            "loguru>=0.7.0" \
            "tomli>=2.0.1; python_version<'3.11'"

        if python_has_pyqt6 >/dev/null; then
            info "Using system PyQt6/Qt6 binary packages."
        else
            warn "System PyQt6/Qt6 packages are not importable."
            info "Trying PyQt6 wheel-only install. This will fail instead of building Qt from source."
            if ! pip_install_binary_only --user "PyQt6>=6.5.0" "PyQt6-Qt6>=6.5.0" "PyQt6-sip>=13.0"; then
                error "Could not install PyQt6 from apt packages or prebuilt wheels."
                error "Install distro Qt6/PyQt6 packages for this board, then rerun this script."
                exit 1
            fi
        fi
    else
        info "x86 detected. Installing dependencies from prebuilt wheels when possible..."
        pip_install --user --prefer-binary \
            "PyQt6>=6.5.0" \
            "opencv-python-headless>=4.8.0" \
            "numpy>=1.24.0" \
            "pyserial>=3.5" \
            "qrcode[pil]>=7.4" \
            "Pillow>=10.0.0" \
            "loguru>=0.7.0" \
            "tomli>=2.0.1; python_version<'3.11'"
    fi

    if ! python_has_pyqt6 >/dev/null; then
        error "PyQt6 with QtQml/QtQuick is still not importable after dependency installation."
        exit 1
    fi
}

install_python_deps

# -- Step 3: Install package ---------------------------------------------------
info "Installing $DISPLAY_NAME..."

if ! pip_install --user --no-deps --quiet "$PYPI_PACKAGE" 2>/dev/null; then
    info "PyPI install failed. Installing from GitHub source..."
    require_cmd git
    pip_install --user --no-deps "git+${GITHUB_REPO}"
fi

# -- Step 4: Verify installation ----------------------------------------------
NEO_BIN="$(python3 - <<PY 2>/dev/null || true
import os
import sysconfig

scripts = sysconfig.get_path("scripts", "posix_user")
print(os.path.join(scripts, "$BIN_NAME"))
PY
)"

if [ -n "$NEO_BIN" ] && [ ! -f "$NEO_BIN" ]; then
    NEO_BIN="$(command -v "$BIN_NAME" 2>/dev/null || true)"
fi

if [ -z "$NEO_BIN" ] || [ ! -f "$NEO_BIN" ]; then
    error "Installation failed - '$BIN_NAME' binary not found."
    error "Check the output above for errors."
    exit 1
fi

mkdir -p "$(dirname "$BIN_LINK")"
if [ "$NEO_BIN" != "$BIN_LINK" ]; then
    ln -sf "$NEO_BIN" "$BIN_LINK"
fi

require_cmd ffmpeg
info "Verified launcher: $BIN_LINK"
info "Verified ffmpeg: $(command -v ffmpeg)"

# -- Step 5: Desktop integration ----------------------------------------------
install_desktop_entry() {
    if [ "$SKIP_DESKTOP" = true ]; then
        info "Skipping desktop integration (--no-desktop)."
        return
    fi

    local exec_path="$BIN_LINK"
    local icon_name="$APP_NAME"
    local pkg_icon

    pkg_icon="$(python3 - <<PY 2>/dev/null || true
import importlib.resources

try:
    ref = importlib.resources.files("$PYTHON_MODULE") / "resources" / "images" / "maker_viet_logo.png"
    with importlib.resources.as_file(ref) as path:
        print(path)
except Exception:
    pass
PY
)"

    if [ -n "$pkg_icon" ] && [ -f "$pkg_icon" ]; then
        mkdir -p "$ICON_DIR"
        cp "$pkg_icon" "$ICON_FILE"
        icon_name="$ICON_FILE"
        info "Installed icon: $ICON_FILE"
    fi

    mkdir -p "$(dirname "$DESKTOP_FILE")"
    tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NeoStopMotion
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

# -- Step 6: Ensure ~/.local/bin is in PATH -----------------------------------
ensure_path() {
    local bin_dir="$HOME/.local/bin"
    if [[ ":$PATH:" == *":$bin_dir:"* ]]; then
        return
    fi

    warn "$bin_dir is not in your PATH."

    local shell_rc=""
    case "$(basename "${SHELL:-sh}")" in
        zsh)  shell_rc="$HOME/.zshrc" ;;
        bash) shell_rc="$HOME/.bashrc" ;;
        *)    shell_rc="$HOME/.profile" ;;
    esac

    if [ -f "$shell_rc" ] && ! grep -q 'local/bin' "$shell_rc"; then
        printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$shell_rc"
        info "Added $bin_dir to PATH in $shell_rc"
        info "Run 'source $shell_rc' or open a new terminal to use '$BIN_NAME'."
    fi
}

ensure_path

# -- Done ----------------------------------------------------------------------
echo ""
info "=========================================="
info "  $DISPLAY_NAME installed successfully!"
info "=========================================="
echo ""
echo "  Run:        $BIN_NAME"
echo "  Launcher:   $BIN_LINK"
echo ""
echo "  Uninstall:  curl -sSL $RAW_INSTALL_URL | bash -s -- --uninstall"
echo ""
