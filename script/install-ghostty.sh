#!/usr/bin/env bash
# Build and install Ghostty for the local user.
#
#   macOS -> Homebrew cask (the official signed universal build).
#   Linux -> build from source with the Zig version pinned by the chosen
#            Ghostty tag; installed to ~/.local.
#
# Ghostty's minimum GTK/libadwaita requirements change across releases, so on
# Linux the newest compatible tag is auto-selected from the versions the
# system provides:
#
#   GTK >= 4.18, Adwaita >= 1.7  ->  v1.4.0  (Zig 0.17.0)
#   GTK >= 4.14, Adwaita >= 1.5  ->  v1.3.1  (Zig 0.15.2)
#   GTK >= 4.8,  Adwaita >= 1.2  ->  v1.1.3  (Zig 0.13.0)
#   GTK >= 4.6,  Adwaita >= 1.1  ->  v1.0.1  (Zig 0.13.0)
#
# Tags < v1.2.0 don't use gtk4-layer-shell at all. Tags >= v1.2.0 link the
# distro copy if it's packaged (e.g. Ubuntu 24.04+), otherwise Ghostty
# compiles it from source into ~/.local/lib.
#
# On a headless Linux box (neither DISPLAY nor WAYLAND_DISPLAY set) the
# script exits early. Override with GHOSTTY_FORCE_LINUX=1.
#
# Like the other install-*.sh scripts here, this is for Debian-based distros
# (it uses apt for the build dependencies).

set -euo pipefail
IFS=$'\n\t'

readonly GHOSTTY_REPO="https://github.com/ghostty-org/ghostty.git"
readonly INSTALL_PREFIX="$HOME/.local"
readonly GHOSTTY_DIR="$PROJECTS/ghostty"
readonly ZIG_ROOT="$PROJECTS/ghostty-zig"

# --- helpers -----------------------------------------------------------------

die() { echo >&2 "$*"; exit "${2:-1}"; }

# True if $1 >= $2 (versions in sort -V order).
version_ge() {
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]]
}

require_projects() {
  [[ -n "$PROJECTS" ]] || die \
    "Please run this script after the basic bootstrap setup, so that " \
    "I know where I should download and build ghostty." 10
  [[ -d "$PROJECTS" ]] || die \
    "The projects directory [$PROJECTS] does not exist. Not creating " \
    "by default, since it's a sign that this script is being called at an " \
    "inappropriate time." 20
}

# --- macOS -------------------------------------------------------------------

install_macos() {
  command -v brew >/dev/null 2>&1 || die "Homebrew not found; please install it first." 30
  if brew list --cask ghostty >/dev/null 2>&1; then
    brew upgrade --cask ghostty
  else
    brew install --cask ghostty
  fi
}

# --- Linux -------------------------------------------------------------------

check_headless() {
  if [[ -z "${GHOSTTY_FORCE_LINUX:-}" && -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "No display detected (DISPLAY and WAYLAND_DISPLAY both unset); " \
         "assuming a headless machine and skipping Ghostty."
    exit 0
  fi
}

# Install a list of apt packages, skipping the ones already installed so the
# script is re-runnable without a TTY (sudo needs a password) once deps exist.
apt_install_missing() {
  local missing=() pkg
  for pkg in "$@"; do
    dpkg-query --showformat='${Status}' -W "$pkg" 2>/dev/null \
      | grep -q '^install ok installed' || missing+=("$pkg")
  done

  if (( ${#missing[@]} > 0 )); then
    echo "Installing missing build dependencies:"
    printf '  %s\n' "${missing[@]}"
    sudo apt install --yes --no-install-recommends "${missing[@]}"
  else
    echo "Build dependencies already installed; skipping apt."
  fi
}

install_build_deps() {
  apt_install_missing \
    pkg-config gettext patchelf \
    libgtk-4-dev libadwaita-1-dev
}

# Ghostty >= v1.2.0 uses gtk4-layer-shell (quick terminal on Wayland). If the
# distro packages it, link the system copy; otherwise the build compiles it
# from source into $INSTALL_PREFIX/lib (see fix_rpath).
install_tag_deps() {
  case "$GHOSTTY_TAG" in
    v1.2.*|v1.3.*|v1.4.*)
      if apt-cache show libgtk4-layer-shell-dev >/dev/null 2>&1; then
        apt_install_missing libgtk4-layer-shell-dev
        LAYER_SHELL_SYSTEM=1
      fi
      ;;
  esac
}

# Pick the newest Ghostty tag whose GTK/libadwaita minimums the system meets.
select_ghostty_tag() {
  local gtk ada
  gtk="$(pkg-config --modversion gtk4)" || die "gtk4 not found in pkg-config; is libgtk-4-dev installed?" 40
  ada="$(pkg-config --modversion libadwaita-1)" || die "libadwaita-1 not found in pkg-config; is libadwaita-1-dev installed?" 40

  if   version_ge "$gtk" 4.18 && version_ge "$ada" 1.7; then
    GHOSTTY_TAG="v1.4.0"; ZIG_VERSION="0.17.0"
  elif version_ge "$gtk" 4.14 && version_ge "$ada" 1.5; then
    GHOSTTY_TAG="v1.3.1"; ZIG_VERSION="0.15.2"
  elif version_ge "$gtk" 4.8  && version_ge "$ada" 1.2; then
    GHOSTTY_TAG="v1.1.3"; ZIG_VERSION="0.13.0"
  elif version_ge "$gtk" 4.6  && version_ge "$ada" 1.1; then
    GHOSTTY_TAG="v1.0.1"; ZIG_VERSION="0.13.0"
  else
    die "System GTK [$gtk] / libadwaita [$ada] is too old for any supported Ghostty release (needs >= 4.6 / >= 1.1)." 41
  fi

  echo "System GTK [$gtk] / libadwaita [$ada] -> Ghostty [$GHOSTTY_TAG] (Zig [$ZIG_VERSION])"
}

# Download the exact Zig release the chosen Ghostty tag pins.
ensure_zig() {
  local arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64" ;;
    aarch64) arch="aarch64" ;;
    *) die "Unsupported architecture: $(uname -m)" 50 ;;
  esac

  # Zig renamed its tarballs after 0.13: zig-linux-ARCH-<ver> -> zig-ARCH-linux-<ver>.
  local url
  if [[ "$ZIG_VERSION" == 0.13.* ]]; then
    url="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${arch}-${ZIG_VERSION}.tar.xz"
  else
    url="https://ziglang.org/download/${ZIG_VERSION}/zig-${arch}-linux-${ZIG_VERSION}.tar.xz"
  fi

  local tarball; tarball="$(basename "$url")"
  ZIG_BIN="$ZIG_ROOT/${tarball%.tar.xz}/zig"

  if [[ -x "$ZIG_BIN" ]]; then
    echo "Zig [$ZIG_VERSION] already present at [$ZIG_BIN]"
    return 0
  fi

  echo "Downloading Zig [$ZIG_VERSION] from [$url]"
  mkdir -p "$ZIG_ROOT"
  curl -fL --progress-bar -o "$ZIG_ROOT/$tarball" "$url"
  tar -xf "$ZIG_ROOT/$tarball" -C "$ZIG_ROOT"
  rm "$ZIG_ROOT/$tarball"
}

build_ghostty() {
  if [[ ! -d "$GHOSTTY_DIR" ]]; then
    git clone "$GHOSTTY_REPO" "$GHOSTTY_DIR"
  fi
  git -C "$GHOSTTY_DIR" fetch --tags
  git -C "$GHOSTTY_DIR" checkout -q "$GHOSTTY_TAG"

  # -p sets up the FHS layout (desktop file, shell integration, etc.) under
  # the install prefix. Ghostty tags < v1.2.0 don't use gtk4-layer-shell at
  # all; newer tags build it from source unless LAYER_SHELL_SYSTEM links the
  # distro copy.
  local extra=()
  if [[ "${LAYER_SHELL_SYSTEM:-}" == 1 ]]; then
    extra+=(-fsys=gtk4-layer-shell)
  fi
  (cd "$GHOSTTY_DIR" && "$ZIG_BIN" build \
    -Doptimize=ReleaseFast \
    -p "$INSTALL_PREFIX" \
    "${extra[@]}")
}

# The bundled gtk4-layer-shell lands in $prefix/lib; point the binary at it
# instead of requiring LD_LIBRARY_PATH.
fix_rpath() {
  local bin="$INSTALL_PREFIX/bin/ghostty"
  [[ -f "$INSTALL_PREFIX/lib/libgtk4-layer-shell.so.0" ]] || return 0
  command -v patchelf >/dev/null 2>&1 || return 0
  patchelf --set-rpath '$ORIGIN/../lib' "$bin" || echo "warning: patchelf failed; Ghostty may need LD_LIBRARY_PATH=$INSTALL_PREFIX/lib"
}

install_linux() {
  require_projects
  check_headless
  install_build_deps
  select_ghostty_tag
  install_tag_deps
  ensure_zig
  build_ghostty
  fix_rpath
}

# --- main --------------------------------------------------------------------

main() {
  case "$(uname -s)" in
    Darwin) install_macos ;;
    Linux)  install_linux ;;
    *) die "Unsupported platform: $(uname -s)" 60 ;;
  esac

  echo
  if command -v ghostty >/dev/null 2>&1; then
    echo "Ghostty installed successfully: $(command -v ghostty)"
    ghostty --version
  else
    echo "Ghostty installed to [$INSTALL_PREFIX] (not on PATH yet)."
  fi
}

main "$@"
