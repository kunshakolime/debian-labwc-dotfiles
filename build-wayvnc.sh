#!/bin/bash
set -e

# build-wayvnc.sh
#
# Builds and installs a recent wayvnc (>= 0.10) from source when the distro's
# package is too old to support password-only noVNC auth.
#
# wayvnc 0.10 added "allow_broken_crypto", which enables classic VNC password
# (DES) authentication - the scheme noVNC handles natively with a password-only
# prompt. Debian Trixie ships wayvnc 0.9.1, so this compiles aml -> neatvnc ->
# wayvnc from pinned release tags into /usr/local.
#
# Safe to re-run: skips when a recent wayvnc is already available (native
# package or previously built). neatvnc is built with h264 disabled, so no
# FFmpeg libraries are pulled in.
#
# Usage: ./build-wayvnc.sh [--force]
#   --force   rebuild even if a recent wayvnc is already installed
#
# Env:
#   JOBS        ninja parallelism override (default: min(nproc, RAM/512MiB))
#   PREFIX      install prefix (default: /usr/local)
#   BUILD_DIR   scratch dir for sources (default: /tmp/wayvnc-build)

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-/usr/local}"
BUILD_DIR="${BUILD_DIR:-/tmp/wayvnc-build}"

# Marks a successful source install of the patched neatvnc. Without this the
# script would skip on distros whose native wayvnc is already >= 0.10, leaving
# the unpatched (username+password) security types in place.
MARKER="$PREFIX/share/wayvnc/nvnc-vnc-auth-first"

AML_VERSION="v1.0.0"
NEATVNC_VERSION="v1.0.1"
WAYVNC_VERSION="v0.10.1"

version_ge() {
    local va=(${1//./ }) vb=(${2//./ })
    local i
    for i in 0 1 2; do
        local na="${va[$i]:-0}" nb="${vb[$i]:-0}"
        if [ "$na" -lt "$nb" ]; then return 1; fi
        if [ "$na" -gt "$nb" ]; then return 0; fi
    done
    return 0
}

# Cap parallel compile jobs so low-RAM machines (common on ARM VPSes) don't
# OOM: roughly one job per 512 MiB, never exceeding the CPU count. Override
# with JOBS=<n>.
jobs_for_machine() {
    local nproc="$(nproc)" ram_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null)"
    local jobs="$nproc"
    if [ -n "$ram_kb" ] && [ "$ram_kb" -gt 0 ]; then
        local by_ram=$(( ram_kb / 1024 / 512 ))
        [ "$by_ram" -lt 1 ] && by_ram=1
        [ "$jobs" -gt "$by_ram" ] && jobs="$by_ram"
    fi
    echo "$jobs"
}

JOBS="${JOBS:-$(jobs_for_machine)}"
ARCH="$(uname -m)"

# nettle-dev (Trixie/Forky) replaced libnettle-dev (Bookworm and older).
pkg_has_candidate() {
    apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}' | grep -qv "(none)"
}
NETTLE_DEV="nettle-dev"
if pkg_has_candidate libnettle-dev; then
    NETTLE_DEV="libnettle-dev"
fi

current_wayvnc_version() {
    wayvnc --version 2>/dev/null | head -1 | awk '{print $2}'
}

CURRENT="$(current_wayvnc_version)"
[ -n "$CURRENT" ] || CURRENT="0.0.0"

if [ "$FORCE" -ne 1 ] && [ -f "$MARKER" ] && version_ge "$CURRENT" "0.10.0"; then
    echo "Patched wayvnc $CURRENT already installed — nothing to build."
    exit 0
fi

echo "Building patched wayvnc >= 0.10 from source (current: $CURRENT) on $ARCH, $JOBS parallel job(s)..."

# ===== Build dependencies =====
sudo apt install -y \
  meson \
  ninja-build \
  gcc \
  pkg-config \
  patch \
  curl \
  libpixman-1-dev \
  libgnutls28-dev \
  "$NETTLE_DEV" \
  zlib1g-dev \
  libgbm-dev \
  libdrm-dev \
  libxkbcommon-dev \
  libwayland-dev \
  libjansson-dev \
  libpam0g-dev

# ===== Fetch pinned sources =====
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
rm -rf ./* 2>/dev/null || true

curl -fsSL -O "https://github.com/any1/aml/archive/refs/tags/${AML_VERSION}.tar.gz"
curl -fsSL -O "https://github.com/any1/neatvnc/archive/refs/tags/${NEATVNC_VERSION}.tar.gz"
curl -fsSL -O "https://github.com/any1/wayvnc/archive/refs/tags/${WAYVNC_VERSION}.tar.gz"

tar -xzf "${AML_VERSION}.tar.gz"
tar -xzf "${NEATVNC_VERSION}.tar.gz"
tar -xzf "${WAYVNC_VERSION}.tar.gz"

# ===== aml =====
cd "aml-${AML_VERSION#v}"
meson setup build --prefix "$PREFIX"
meson compile -C build -j "$JOBS"
sudo meson install -C build
cd ..

# ===== neatvnc (h264/FFmpeg disabled — not needed headless) =====
cd "neatvnc-${NEATVNC_VERSION#v}"
# Reorder security types so classic VNC auth (2) is offered first, making noVNC
# show a password-only prompt. Upstream offers RSA-AES/AppleDH first, which
# noVNC answers with a username+password prompt.
patch -p1 -s < "$SCRIPT_DIR/patches/neatvnc-vnc-auth-first.diff"
meson setup build --prefix "$PREFIX" \
  -Dh264=disabled -Dexamples=false -Dbenchmarks=false -Dtests=false
meson compile -C build -j "$JOBS"
sudo meson install -C build
cd ..

# ===== wayvnc =====
cd "wayvnc-${WAYVNC_VERSION#v}"
meson setup build --prefix "$PREFIX" -Dman-pages=disabled
meson compile -C build -j "$JOBS"
sudo meson install -C build
cd ..

sudo ldconfig

sudo mkdir -p "$PREFIX/share/wayvnc"
sudo touch "$MARKER"

echo ""
echo "===== wayvnc build complete ====="
"$PREFIX/bin/wayvnc" --version || wayvnc --version
echo "Restart labwc (or kill wayvnc and run it again) to pick up the new binary."
